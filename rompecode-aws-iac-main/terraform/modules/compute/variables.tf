variable "project" {
  description = "Nombre del proyecto"
  type        = string
}

variable "vpc_id" {
  description = "ID de la VPC donde se despliega el cómputo"
  type        = string
}

variable "public_subnet_ids" {
  description = "Subredes públicas para el ALB"
  type        = list(string)
}

variable "private_subnet_ids" {
  description = "Subredes privadas para las instancias EC2"
  type        = list(string)
}

variable "instance_type" {
  description = "Tipo de instancia EC2"
  type        = string
  default     = "t3.micro"
}

variable "key_name" {
  description = "Nombre del key pair de EC2 (opcional, dejar null si se usa SSM)"
  type        = string
  default     = null
}

variable "admin_cidr" {
  description = "CIDR permitido para SSH de administración"
  type        = string
  default     = "0.0.0.0/0" # ⚠️ Reemplazar por tu IP pública real, ej: 190.x.x.x/32
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

variable "tags" {
  description = "Tags comunes"
  type        = map(string)
  default     = {}
}
