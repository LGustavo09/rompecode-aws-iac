output "alb_dns_name" {
  description = "URL del ALB - abrir en el navegador para la demo"
  value       = module.compute.alb_dns_name
}

output "vpc_id" {
  description = "ID de la VPC del proyecto"
  value       = module.vpc.vpc_id
}

output "public_subnet_ids" {
  description = "IDs de las subredes públicas"
  value       = module.vpc.public_subnet_ids
}

output "private_subnet_ids" {
  description = "IDs de las subredes privadas"
  value       = module.vpc.private_subnet_ids
}

output "asg_name" {
  description = "Nombre del Auto Scaling Group (usar en inventario dinámico de Ansible)"
  value       = module.compute.asg_name
}
