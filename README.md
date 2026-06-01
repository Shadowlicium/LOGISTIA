# LOGISTIA — CI/CD sur Proxmox

Projet: déploiement de VMs sur Proxmox avec Terraform + Ansible + GitHub Actions.

Architecture (résumé):
- VLAN 10 (DMZ): serveur web Apache, supervision (Grafana) et Mail (Mailcow)
- VLAN 20: base de données
- VLAN 30: GitHub Runner self-hosted
- VLAN 99: serveur de backup

Stack:
- Terraform: création des VM, config réseau et provisioning initial (cloud-init)
- Ansible: configuration système, déploiement applicatif, durcissement
- GitHub Actions: lint, tests, terraform plan/apply, exécution Ansible, scans

Démarrage rapide:
1. Remplir `infra/terraform/variables.tf` avec les informations Proxmox.
2. Lancer `terraform init` puis `terraform plan` dans `infra/terraform`.
3. Après création des VMs, configurer `ansible/inventory.ini` et lancer:

```bash
ansible-playbook -i ansible/inventory.ini ansible/playbooks/site.yml
```

Voir les fichiers modèles dans `infra/terraform`, `ansible/` et `.github/workflows`.
