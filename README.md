# LOGISTIA — CI/CD sur Proxmox

Projet: déploiement de VMs sur Proxmox avec Terraform + Ansible + GitHub Actions.

Architecture (résumé):
- VLAN 10 (DMZ): serveur web Apache, supervision (Grafana) et mail (Postfix/Dovecot)
- VLAN 20: base de données et IA (Ollama)
- VLAN 30: GitHub Runner self-hosted
- VLAN 99: serveur de backup

Réseau statique:
- `web` = 10.10.10.10/24
- `grafana` = 10.10.10.11/24
- `postfix` = 10.10.10.12/24
- `db` = 10.10.20.10/24
- `ollama` = 10.10.20.11/24
- `gh-runner` = 10.10.30.10/24
- `backup` = 10.10.99.10/24

Stack:
- Terraform: création des conteneurs LXC sur Proxmox, configuration réseau et provisioning initial
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
