# IMPORTANTE: reemplazar los valores antes del primer `terraform init`.
# El bucket S3 y la tabla DynamoDB deben crearse ANTES de aplicar esto
# (a mano una sola vez, o con un mini-script bootstrap aparte,
# ya que el backend no puede crear su propia infraestructura).
#
# Crear bucket:
#   aws s3api create-bucket --bucket rompecode-tfstate-<sufijo-unico> --region us-east-1
# Crear tabla de lock:
#   aws dynamodb create-table --table-name rompecode-tf-lock \
#     --attribute-definitions AttributeName=LockID,AttributeType=S \
#     --key-schema AttributeName=LockID,KeyType=HASH \
#     --billing-mode PAY_PER_REQUEST

terraform {
  backend "s3" {
    bucket         = "rompecode-tfstate-julio2026"
    key            = "rompecode/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "rompecode-tf-lock"
    encrypt        = true
  }
}
