variable "aws_region" {
  description = "Región de AWS donde se despliega todo"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Nombre del proyecto (usado en tags y nombres de recursos)"
  type        = string
  default     = "rompecode"
}

variable "environment" {
  description = "Ambiente de despliegue (dev/prod)"
  type        = string
  default     = "dev"
}

variable "vpc_cidr" {
  type    = string
  default = "10.0.0.0/16"
}

variable "public_subnet_cidrs" {
  type    = list(string)
  default = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "private_subnet_cidrs" {
  type    = list(string)
  default = ["10.0.10.0/24", "10.0.20.0/24"]
}

variable "instance_type" {
  type    = string
  default = "t3.micro"
}

variable "admin_cidr" {
  description = "Tu IP pública en formato CIDR, ej: 190.12.34.56/32. NO dejar 0.0.0.0/0 en producción."
  type        = string
  default     = "0.0.0.0/0"
}

variable "asg_min_size" {
  type    = number
  default = 2
}

variable "asg_desired_capacity" {
  type    = number
  default = 2
}

variable "asg_max_size" {
  type    = number
  default = 6
}
