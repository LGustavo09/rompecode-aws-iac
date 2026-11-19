# RompeCode Cloud Hub

**Equipo:** Los Rompe Código
**Proyecto:** Aplicación Web de Alta Disponibilidad con Balanceo de Carga en AWS (IaC & DevOps)
**Duración:** 8 semanas | **Nivel:** Intermedio | **Stack:** Terraform + Ansible + GitHub Actions

---

## 1. Descripción

Infraestructura resiliente y 100% automatizada (sin clics en consola) que despliega
una aplicación web estática balanceada entre dos Availability Zones, con Auto Scaling
por CPU y un pipeline CI/CD completo.

## 2. Diagrama de Arquitectura

```
                              INTERNET
                                 │
                        ┌────────▼────────┐
                        │   Route 53 DNS   │  (opcional)
                        └────────┬────────┘
                                 │
                        ┌────────▼────────┐
                        │  Application     │  ← ALB (público, Multi-AZ)
                        │  Load Balancer   │    Listener HTTP:80
                        └───┬─────────┬────┘
                            │         │
              ┌─────────────▼──┐   ┌──▼─────────────┐
              │     AZ-1a       │   │     AZ-1b       │
              │  Public Subnet  │   │  Public Subnet  │
              │  NAT Gateway A  │   │  NAT Gateway B  │
              └──────┬──────────┘   └────────┬────────┘
                     │                        │
              ┌──────▼──────────┐   ┌─────────▼────────┐
              │  AZ-1a Private   │   │  AZ-1b Private    │
              │  EC2 (Nginx) x1  │   │  EC2 (Nginx) x1   │  ← Auto Scaling Group
              └──────────────────┘   └────────────────────┘   (Min:2 Deseado:2 Máx:6)

  CI/CD:  GitHub → GitHub Actions → terraform plan/apply → Ansible playbook
```

**VPC:** `10.0.0.0/16` · **Públicas:** `10.0.1.0/24`, `10.0.2.0/24` · **Privadas:** `10.0.10.0/24`, `10.0.20.0/24`

## 3. Estructura del repositorio

```
.
├── .github/workflows/
│   ├── terraform-ci.yml      # validate + plan (en Pull Requests)
│   └── terraform-cd.yml      # apply + ansible (en merge a main)
├── terraform/
│   ├── main.tf                # orquesta los módulos
│   ├── variables.tf
│   ├── outputs.tf
│   ├── backend.tf             # remote state S3 + DynamoDB
│   └── modules/
│       ├── vpc/                # red: VPC, subnets, IGW, NAT
│       └── compute/             # ALB, ASG, Launch Template, Security Groups
├── ansible/
│   ├── ansible.cfg
│   ├── aws_ec2.yml             # inventario dinámico
│   ├── site.yml                # playbook principal
│   ├── group_vars/
│   └── roles/
│       ├── common/              # paquetes base, firewall, usuario deploy
│       ├── webserver/            # instala y configura Nginx
│       └── deploy/               # despliega la Landing Page
├── app/
│   └── index.html               # Landing Page dinámica
└── README.md                    # este documento
```

## 4. Cómo desplegar (paso a paso)

### 4.1 Prerrequisitos
```bash
# Credenciales AWS configuradas
aws configure

# Crear bucket S3 y tabla DynamoDB para el backend (una sola vez)
aws s3api create-bucket --bucket rompecode-tfstate-<sufijo-unico> --region us-east-1
aws dynamodb create-table --table-name rompecode-tf-lock \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST
```
Actualiza `terraform/backend.tf` con el nombre real del bucket.

### 4.2 Desplegar infraestructura
```bash
cd terraform
terraform init
terraform plan
terraform apply
```

### 4.3 Configurar servidores
```bash
cd ../ansible
ansible-inventory -i aws_ec2.yml --graph   # verifica que detecta las EC2
ansible-playbook -i aws_ec2.yml site.yml
```

### 4.4 Probar
```bash
terraform output alb_dns_name
# Abre esa URL en el navegador y refresca varias veces
```

### 4.5 Destruir al terminar (control de costos)
```bash
cd terraform
terraform destroy
```

## 5. Pipeline CI/CD

| Job | Trigger | Acción |
|---|---|---|
| `validate` | Pull Request | `terraform fmt`, `validate`, `tflint` |
| `plan` | Pull Request | `terraform plan` + comentario automático en el PR |
| `apply` | Merge a `main` | `terraform apply` (requiere aprobación manual vía GitHub Environments) |
| `configure` | Después de `apply` | Ejecuta el playbook de Ansible |

**Secrets necesarios en GitHub:** `AWS_ROLE_ARN` (rol OIDC, sin llaves de acceso estáticas).

## 6. Seguridad

- `ec2-sg`: solo acepta tráfico HTTP desde `alb-sg` (sin exposición directa a Internet).
- IMDSv2 obligatorio (`http_tokens = required`) en las instancias.
- Sin credenciales hardcodeadas — todo vía GitHub Secrets / OIDC.
- Tags obligatorios en todos los recursos: `Project`, `Team`, `Environment`.

## 7. Evidencias a recolectar (Semana 8)

- [ ] Captura del ALB respondiendo y balanceando entre instancias
- [ ] Captura de CloudWatch mostrando CPU > 70% y la 3ra instancia creada
- [ ] Logs del pipeline (`validate`, `plan`, `apply`, `configure`) exitosos
- [ ] Salida de `ansible-playbook` mostrando `changed=0` en 2da corrida
- [ ] Video demo (≤10 min) siguiendo el guion de sustentación

## 8. Equipo — Los Rompe Código

| Rol | Responsable | Frente |
|---|---|---|
| Terraform Lead | Dev 1 | VPC, backend remoto |
| AWS Architect | Dev 2 | ALB, compute, health checks |
| Ansible Specialist | Dev 3 | Roles, playbooks |
| DevOps Lead | Dev 4 | CI/CD, GitHub Actions, OIDC |
