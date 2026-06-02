Terraform infra pour LOGISTIA

Instructions rapides:

1. Créer un fichier local de variables:

```bash
cp terraform.tfvars.example terraform.tfvars
```

`terraform.tfvars` contient des secrets et ne doit jamais être commité.

2. Initialiser et valider:

```bash
cd infra/terraform
terraform init
terraform validate
```

3. Planifier:

```bash
terraform plan
```

4. Pour appliquer (attention — crée des conteneurs LXC):

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
