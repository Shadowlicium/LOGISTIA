Terraform infra pour LOGISTIA

Instructions rapides:

1. Exporter variables d'environnement pour Proxmox:

```bash
export TF_VAR_proxmox_url="https://proxmox.local:8006/api2/json"
export TF_VAR_proxmox_user="terraform@pve"
export TF_VAR_proxmox_password="<password>"
```

2. Initialiser et planifier:

```bash
cd infra/terraform
terraform init
terraform plan
```

3. Pour appliquer (attention — crée des VMs):

```bash
terraform apply -auto-approve
```

Personnalisation: modifier les modules dans `infra/terraform/modules/` et les cloud-init dans `infra/terraform/cloudinit/`.
