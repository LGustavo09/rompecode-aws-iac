# Ansible — Los Rompe Código

Configuración idempotente de los servidores web desplegados por Terraform.

## Estructura

```
ansible/
├── ansible.cfg          # Config general + inventario dinámico habilitado
├── aws_ec2.yml           # Inventario dinámico (descubre EC2 por tag)
├── site.yml              # Playbook principal
├── group_vars/
│   ├── all.yml           # Variables globales
│   └── webservers.yml    # Variables del grupo webservers
└── roles/
    ├── common/            # Paquetes base, firewall, usuario deploy
    ├── webserver/          # Instalación y configuración de Nginx
    └── deploy/             # Copia la Landing Page al servidor
```

## Requisitos previos

```bash
pip install ansible boto3 botocore
ansible-galaxy collection install amazon.aws ansible.posix
```

Credenciales AWS disponibles vía variables de entorno o perfil (`aws configure`).

## Verificar el inventario dinámico

```bash
cd ansible
ansible-inventory -i aws_ec2.yml --graph
```

Deberías ver las instancias EC2 del Auto Scaling Group agrupadas bajo `webservers`.

## Ejecutar el playbook

```bash
ansible-playbook -i aws_ec2.yml site.yml
```

## Verificar idempotencia (requisito de evaluación)

Ejecutar 2 o 3 veces seguidas. La primera corrida mostrará `changed`,
las siguientes deben mostrar **`changed=0`**:

```bash
ansible-playbook -i aws_ec2.yml site.yml
ansible-playbook -i aws_ec2.yml site.yml   # <- debe dar changed=0
```

## Notas de conectividad

Las instancias están en subredes **privadas** (sin IP pública), por lo que
Ansible debe ejecutarse desde:
- Un runner de GitHub Actions con acceso a la VPC (via Session Manager / SSM), o
- Un bastion host / VPN dentro de la misma VPC.

Se recomienda usar **AWS Systems Manager (SSM)** en vez de SSH directo para
mantener el principio de mínimo privilegio (sin puertos 22 abiertos a Internet).
