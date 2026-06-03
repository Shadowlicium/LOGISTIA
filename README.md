# LOGISTIA - Infrastructure Proxmox

Infrastructure de fin d'année basée sur Proxmox, Terraform, Ansible et GitHub Actions.

L'objectif est de déployer des conteneurs LXC séparés par VLAN, avec une DMZ, une zone data, une zone supervision/IA et une zone backup. Les secrets restent hors du dépôt.

## Architecture

### VLANs

- **VLAN 10 - DMZ**
  - `web` (`10.10.10.10`) : serveur Apache
  - `mail-relay` (`10.10.10.12`) : relais SMTP avec analyse Rspamd

- **VLAN 20 - Data**
  - `db` (`10.10.20.10`) : PostgreSQL
  - `mail-data` (`10.10.20.12`) : serveur mail interne Postfix + Dovecot

- **VLAN 40 - Supervision & IA**
  - `grafana` (`10.10.40.10`) : supervision
  - `ollama` (`10.10.40.11`) : analyse de logs / IA

- **VLAN 90 - Management**
  - Proxmox et accès d'administration

- **VLAN 99 - Backup**
  - `backup` (`10.10.99.10`) : sauvegardes rsync

### Flux

- Les conteneurs ne sont pas exposés directement à Internet.
- Le firewall Debian route et filtre les VLANs.
- Le GitHub runner doit être installé hors Terraform dans le réseau interne, par exemple en VLAN 30.
- Ansible part du runner ou d'une machine d'administration ayant accès aux VLANs.
- Le mail arrive sur `mail-relay` en DMZ, est analysé, puis est relayé en SMTP vers `mail-data` dans le VLAN 20.

## Déploiement

### 1. Variables Terraform

```bash
cd infra/terraform
cp terraform.tfvars.example terraform.tfvars
```

Remplir `terraform.tfvars` avec les valeurs Proxmox et la clé SSH publique :

```hcl
proxmox_url      = "https://proxmox.example.local:8006/api2/json"
proxmox_user     = "terraform@pve"
proxmox_password = "change-me"
ssh_public_key   = "ssh-ed25519 AAAA..."
```

`terraform.tfvars` est ignoré par Git.

### 2. Créer les conteneurs

```bash
terraform init
terraform plan -out=plan.tfplan
terraform apply plan.tfplan
```

Terraform injecte uniquement une clé SSH publique dans les conteneurs. Aucun mot de passe root n'est stocké dans le dépôt.

### 3. Variables Ansible locales

```bash
cd ../..
cp ansible/group_vars/all.yml.example ansible/group_vars/all.yml
cp ansible/group_vars/mail.yml.example ansible/group_vars/mail.yml
ansible-vault encrypt ansible/group_vars/mail.yml
```

`all.yml` contient la clé publique utilisée pour créer les utilisateurs d'administration par machine. `mail.yml` contient les comptes mail et doit rester chiffré/local.

### 4. Exécuter Ansible

Depuis une machine qui peut joindre les VLANs :

```bash
ansible-playbook -i ansible/inventory.ini ansible/playbooks/site.yml --ask-vault-pass
```

Le playbook :

- crée un utilisateur d'administration par machine (`web-apache`, `db-postgres`, `mail-data`, etc.)
- installe Apache, PostgreSQL, Grafana, Postfix/Dovecot, Rspamd, Ollama et les services de backup
- désactive l'authentification SSH par mot de passe

## GitHub Runner

Le runner GitHub Actions n'est pas créé par Terraform dans ce dépôt. Il doit être mis en place manuellement sur une machine interne capable d'accéder à Proxmox et aux VLANs privés, par exemple dans le VLAN 30.

Installation recommandée :

1. Aller dans GitHub : `Settings` -> `Actions` -> `Runners` -> `New self-hosted runner`.
2. Choisir Linux x64.
3. Se connecter sur la machine choisie pour héberger le runner.
4. Copier/coller les commandes affichées par GitHub.

Le dépôt ne maintient pas de script d'installation custom du runner : les commandes officielles GitHub sont la source fiable.

### Secrets GitHub nécessaires

Pour `.github/workflows/deploy-with-self-hosted-runner.yml` :

- `PROXMOX_URL`
- `PROXMOX_USER`
- `PROXMOX_PASSWORD`
- `SSH_PUBLIC_KEY`
- `ANSIBLE_SSH_PRIVATE_KEY`
- `ANSIBLE_MAIL_VARS`

`SSH_PUBLIC_KEY` est injectée par Terraform. `ANSIBLE_SSH_PRIVATE_KEY` est la clé privée correspondante, utilisée par le runner pour SSH vers les conteneurs.

### Déploiement depuis GitHub Actions

Le workflow `Deploy with Self-Hosted Runner` se lance manuellement depuis l'onglet `Actions`.

Il exécute, sur le runner interne :

1. `terraform init`
2. `terraform plan`
3. `terraform apply` si l'option `terraform_action` vaut `apply`
4. Ansible si l'option `run_ansible` est activée

Le state Terraform n'est pas stocké dans le dépôt. Par défaut, le workflow utilise :

```text
/srv/logistia/terraform/terraform.tfstate
```

Sur un runner en conteneur, ce dossier doit être monté sur un volume persistant. Sinon, au redémarrage du conteneur, Terraform perdra son state et risque de vouloir recréer des ressources déjà existantes.

Le chemin peut être changé avec une variable GitHub Actions nommée `TERRAFORM_STATE_PATH`.

## Accès SSH

Avant le premier passage Ansible, l'accès se fait en root avec la clé injectée par Terraform :

```bash
ssh -i ~/.ssh/logistia_ed25519 root@10.10.10.10
```

Après Ansible, utiliser les comptes d'administration par machine :

```bash
ssh -i ~/.ssh/logistia_ed25519 web-apache@10.10.10.10
ssh -i ~/.ssh/logistia_ed25519 db-postgres@10.10.20.10
ssh -i ~/.ssh/logistia_ed25519 mail-data@10.10.20.12
ssh -i ~/.ssh/logistia_ed25519 mail-relay@10.10.10.12
ssh -i ~/.ssh/logistia_ed25519 grafana@10.10.40.10
ssh -i ~/.ssh/logistia_ed25519 ollama-ia@10.10.40.11
ssh -i ~/.ssh/logistia_ed25519 backup@10.10.99.10
```

Si les VLANs ne sont pas accessibles directement depuis le poste, passer par Proxmox ou par le réseau d'administration.

## Structure

```text
.
├── .github/workflows/
│   ├── ci-cd.yml
│   └── deploy-with-self-hosted-runner.yml
├── ansible/
│   ├── ansible.cfg
│   ├── inventory.ini
│   ├── group_vars/
│   ├── playbooks/site.yml
│   └── roles/
└── infra/terraform/
    ├── main.tf
    ├── variables.tf
    ├── outputs.tf
    ├── terraform.tfvars.example
    └── modules/vm/
```

## Sécurité

- Les fichiers `terraform.tfvars`, `terraform.tfstate`, `.terraform/` et les vrais fichiers `group_vars/*.yml` sont ignorés par Git.
- Les mots de passe mail doivent être stockés dans `ansible/group_vars/mail.yml`, idéalement chiffré avec Ansible Vault.
- Les conteneurs ne sont pas exposés directement à Internet.
- Le runner self-hosted doit être interne au réseau, mais il est géré hors Terraform.
- Le state Terraform devrait idéalement être déplacé vers un backend distant chiffré.
