variable "region" {

  default     = "ap-south-1"
  description = "Default region the project is created on"

}

variable "access_key" {

  default     = "AKIA56ODWEEZII5BZX73"
  description = "Access key of the terraform IAM user"

}

variable "secret_key" {

  default     = "jDB0dVB/Nm7CBfdYRcXB6DRfPu5aFPnX9TgNV+M5"
  description = "Secret key of the terraform IAM user"

}

variable "project" {

  default     = "Zomato"
  description = "Name of the project"

}

locals {

  common_tags = {
    "project"     = var.project
    "environment" = var.environment
  }

}

locals {

  subnets = length(data.aws_availability_zones.available.names)

}

variable "instance_ami" {

  default = "ami-0cca134ec43cf708f"

}

variable "instance_type" {

  default = "t2.micro"

}

variable "environment" {

  default = "dev"

}

variable "vpc_cidr" {

  default = "172.16.0.0/16"

}

variable "pub_domain" {

  default     = "manumohan.online"
  description = "Domain name to be used as the public hosted zones"
}

variable "pri_domain" {

  default     = "manumohan.local"
  description = "Domain name to be used as the private hosted zones"
}

variable "db_name" {

  default = "blog"

}

variable "db_user" {

  default = "bloguser"

}

variable "db_pass" {

  default = "bloguser123"

}

locals {

  db-host = "db.${var.pri_domain}"
  wp-host = "wordpress.${var.pub_domain}"
}

variable "public_ips" {

  type = list(string)
  default = [
  "117.207.46.150/32"]

}

variable "frontend_ports" {

  type    = list(string)
  default = ["80", "443", "8080"]

}

variable "frontend_ssh_access" {

  default = false

}
variable "backend_ssh_access" {

  default = false

}

