output "alb_dns_name" {
  description = "URL del ALB - abrir en el navegador para la demo"
  value       = module.compute.alb_dns_name
}

output "vpc_id" {
  value = module.vpc.vpc_id
}

output "public_subnet_ids" {
  value = module.vpc.public_subnet_ids
}

output "private_subnet_ids" {
  value = module.vpc.private_subnet_ids
}

output "asg_name" {
  description = "Nombre del Auto Scaling Group (usar en inventario dinámico de Ansible)"
  value       = module.compute.asg_name
}
