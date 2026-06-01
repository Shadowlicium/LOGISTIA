Terraform infra pour LOGISTIA

Instructions rapides:

1. Exporter variables d'environnement pour Proxmox:

```bash
export TF_VAR_proxmox_url="https://proxmox.local:8006/api2/json"
export TF_VAR_proxmox_user="terraform@pve"
export TF_VAR_proxmox_password="<password>"
export TF_VAR_root_password="<root-password>"
export TF_VAR_ssh_public_key="$(cat ~/.ssh/id_rsa.pub)"
```

2. Initialiser et planifier:

```bash
cd infra/terraform
terraform init
terraform plan
```

3. Pour appliquer (attention — crée des conteneurs LXC):

```bash
terraform apply -auto-approve
```

Les conteneurs sont créés avec des IP statiques par VLAN. Les adresses par défaut utilisées sont:
- web: 10.10.10.10/24
- grafana: 10.10.10.11/24
- postfix: 10.10.10.12/24
- db: 10.10.20.10/24
- ollama: 10.10.20.11/24
- gh-runner: 10.10.30.10/24
- backup: 10.10.99.10/24

Personnalisation: modifier les modules dans `infra/terraform/modules/` et utiliser des templates LXC Proxmox pour les conteneurs.
