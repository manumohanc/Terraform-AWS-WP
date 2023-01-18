output "Wordpress_Link" {

  value = local.wp-host

}

output "vpc-module-return" {

  value = module.vpc

}

output "frontend" {

  value = data.template_file.frontend-cred.rendered

}

output "backend" {

  value = data.template_file.backend-cred.rendered

}
