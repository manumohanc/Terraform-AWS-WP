data "aws_availability_zones" "available" {

  state = "available"

}

data "aws_route53_zone" "mydomain" {

  name = var.pub_domain

}

data "template_file" "frontend-cred" {

  template = file("${path.module}/frontend-setup.sh")
  vars = {
    DB_NAME     = var.db_name
    DB_USER     = var.db_user
    DB_PASSWORD = var.db_pass
    DB_HOST     = local.db-host
  }

}

data "template_file" "backend-cred" {

  template = file("${path.module}/backend-setup.sh")
  vars = {
    DB_NAME     = var.db_name
    DB_USER     = var.db_user
    DB_PASSWORD = var.db_pass
  }

}
