module "vpc" {

  source      = "/home/ec2-user/vpc-module-main"
  project     = var.project
  environment = var.environment
  vpc_cidr    = var.vpc_cidr
}

resource "aws_ec2_managed_prefix_list" "prefix-list" {

  name           = "${var.project}-${var.environment}-prefixlist"
  address_family = "IPv4"
  max_entries    = length(var.public_ips)
  dynamic "entry" {
    for_each = var.public_ips
    iterator = item
    content {
      cidr = item.value
    }
  }
  tags = {
    Name = "${var.project}-${var.environment}-prefixlist"
  }
}

resource "aws_security_group" "Bastion-traffic" {

  name_prefix = "${var.project}-${var.environment}-bastion-"
  description = "Allow SSH inbound traffic over port 22"
  vpc_id      = module.vpc.vpc_id

  ingress {
    description     = "SSH traffic over port 22"
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    prefix_list_ids = [aws_ec2_managed_prefix_list.prefix-list.id]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {

    "Name" = "${var.project}-${var.environment}-bastion"
  }

  lifecycle {
    create_before_destroy = true
  }

}

resource "aws_security_group" "Frontend-traffic" {

  name_prefix = "${var.project}-${var.environment}-frontend-"
  description = "Allow HTTP traffic over port 80,443 and SSH inbound traffic over port 22 from bastion server/everyone"
  vpc_id      = module.vpc.vpc_id

  dynamic "ingress" {
    for_each = toset(var.frontend_ports)
    iterator = port
    content {
      from_port        = port.value
      to_port          = port.value
      protocol         = "tcp"
      cidr_blocks      = ["0.0.0.0/0"]
      ipv6_cidr_blocks = ["::/0"]
    }
  }

  ingress {
    description     = "SSH traffic over port 22"
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    cidr_blocks     = var.frontend_ssh_access == true ? ["0.0.0.0/0"] : null
    security_groups = [aws_security_group.Bastion-traffic.id]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {

    "Name" = "${var.project}-${var.environment}-frontend"
  }

  lifecycle {
    create_before_destroy = true
  }

}

resource "aws_security_group" "Backend-traffic" {

  name_prefix = "${var.project}-${var.environment}-backend-"
  description = "Allow mysql traffic over port 3306 and SSH inbound traffic over port 22 from bastion server/everyone"
  vpc_id      = module.vpc.vpc_id

  ingress {
    description     = "MYSQL traffic over port 3306"
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.Frontend-traffic.id]
  }

  ingress {
    description     = "SSH traffic over port 22"
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    cidr_blocks     = var.backend_ssh_access == true ? ["0.0.0.0/0"] : null
    security_groups = [aws_security_group.Bastion-traffic.id]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {

    "Name" = "${var.project}-${var.environment}-backend"
  }

  lifecycle {
    create_before_destroy = true
  }

}

resource "aws_key_pair" "ssh_key" {

  key_name   = "${var.project}-${var.environment}"
  public_key = file("mykey.pub")
  tags = {

    "Name" = "${var.project}-${var.environment}"

  }

}

resource "aws_instance" "frontend" {

  ami                    = var.instance_ami
  instance_type          = var.instance_type
  key_name               = aws_key_pair.ssh_key.id
  vpc_security_group_ids = [aws_security_group.Frontend-traffic.id]
  subnet_id              = module.vpc.public_subnets.0
  user_data              = data.template_file.frontend-cred.rendered
  depends_on             = [aws_instance.backend]
  tags = {

    "Name" = "${var.project}-${var.environment}-frontend"
  }

}

resource "aws_instance" "bastion" {

  ami                    = var.instance_ami
  instance_type          = var.instance_type
  key_name               = aws_key_pair.ssh_key.id
  vpc_security_group_ids = [aws_security_group.Bastion-traffic.id]
  subnet_id              = module.vpc.public_subnets.1
  tags = {

    "Name" = "${var.project}-${var.environment}-bastion"
  }

}

resource "aws_instance" "backend" {

  ami                    = var.instance_ami
  instance_type          = var.instance_type
  key_name               = aws_key_pair.ssh_key.id
  vpc_security_group_ids = [aws_security_group.Backend-traffic.id]
  subnet_id              = module.vpc.private_subnets.0
  user_data              = data.template_file.backend-cred.rendered
  depends_on             = [module.vpc.aws_nat_gateway]
  tags = {

    "Name" = "${var.project}-${var.environment}-backend"
  }

}

resource "aws_route53_zone" "private" {

  name = var.pri_domain
  vpc {
    vpc_id = module.vpc.vpc_id
  }
}

resource "aws_route53_record" "db" {

  zone_id = aws_route53_zone.private.zone_id
  name    = local.db-host
  type    = "A"
  ttl     = 300
  records = [aws_instance.backend.private_ip]
}

resource "aws_route53_record" "wordpress" {

  zone_id = data.aws_route53_zone.mydomain.zone_id
  name    = local.wp-host
  type    = "A"
  ttl     = 300
  records = [aws_instance.frontend.public_ip]
}


