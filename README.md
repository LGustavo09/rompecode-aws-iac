# RompeCode Dynamic Portal

Portal en dos zonas de disponibilidad con un Application Load Balancer y un Auto Scaling Group de instancias privadas. Terraform administra la infraestructura. Cada EC2 instala el portal al arrancar y Ansible verifica la configuración mediante Systems Manager.

## Prerrequisitos

- Terraform 1.7.5, AWS CLI v2, Ansible, Python y Session Manager Plugin.
- Acceso a AWS en us-east-1, bucket de estado `rompecode-tfstate-julio2026` con versionado y tabla `rompecode-tf-lock` con clave de partición `LockID`.
- Dos Elastic IP y capacidad suficiente para las instancias EC2 y los NAT Gateway.
- Para Ansible, instala las colecciones con `ansible-galaxy collection install amazon.aws ansible.posix` y las dependencias Python `boto3` y `botocore`.

## Despliegue de prueba

Trabaja en la versión aprobada y verifica primero tu identidad y región de AWS. Desde la raíz:

```bash
cd terraform
terraform init
terraform fmt -check -recursive
terraform validate
tflint --recursive
terraform plan -out=tfplan
```

Revisa el resumen y los recursos antes de continuar. Si el plan coincide con lo esperado:

```bash
terraform apply tfplan
terraform output -raw alb_dns_name
export ANSIBLE_SSM_BUCKET=$(terraform output -raw ansible_transfer_bucket)
cd ../ansible
ansible-inventory -i aws_ec2.yml --graph
ansible-playbook -i aws_ec2.yml site.yml
```

Comprueba que las instancias aparecen en SSM y tienen estado healthy en el Target Group. Consulta `/health` y `/api/info` en el ALB. Repite la consulta para comprobar las instancias y las zonas que atienden tráfico. Ejecuta una segunda vez el playbook y registra el resumen de idempotencia.

La prueba de carga requiere una sesión de SSM. Abre un túnel por instancia hacia el puerto 80 y visita la dirección local del túnel en tu navegador. Ejecuta la prueba solo durante la ventana de demostración y captura el resultado en CloudWatch, el ASG y el Target Group. La ruta de carga está restringida a conexiones locales en cada EC2.

## GitHub Actions

Terraform CI ejecuta Validate y Plan en los pull requests. Configura `AWS_ROLE_ARN` como secreto de repositorio para el rol de CI. Configura por separado `AWS_DEPLOY_ROLE_ARN` en el entorno `production` para un rol OIDC de despliegue limitado a ese entorno. Habilita la revisión manual y restringe el entorno a `main`. La corrida oficial de Terraform CD se inicia manualmente desde `main` y espera aprobación antes de aplicar cambios. El trabajo Configure espera la conexión de las instancias a SSM antes de lanzar Ansible.

## Destrucción

Una vez recogidas las evidencias, ejecuta `terraform destroy` desde `terraform` con la misma cuenta, región y backend. Verifica que no queden el ALB, los NAT Gateway ni las Elastic IP del proyecto. Conserva el bucket de estado y la tabla de bloqueo.
