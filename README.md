# LOGISTIA - Infrastructure Proxmox

LOGISTIA est un projet d'infrastructure de fin d'annee base sur Proxmox, Terraform, Ansible et GitHub Actions.

Le projet deploie des conteneurs LXC separes par VLAN afin de presenter une architecture lisible, securisee et maintenable. Terraform cree les machines sur Proxmox. Ansible installe et configure les services applicatifs. Les secrets restent hors du depot Git.

## Objectif

L'infrastructure met en place :

- une DMZ pour le serveur web et le relais mail
- une zone data pour PostgreSQL et le serveur mail interne
- une zone supervision et IA pour Grafana et Ollama
- une zone backup separee, optionnelle au deploiement
- un runner GitHub Actions interne, gere hors Terraform
- une configuration SSH par cle, sans mot de passe root stocke dans le depot

Le mail entrant arrive sur le relais en DMZ, passe par l'analyse Rspamd, puis est transmis au serveur mail interne dans le VLAN data.

## Architecture

### VLANs

| VLAN | Zone | Machines |
|---|---|---|
| 10 | DMZ | `web-apache` `10.10.10.10`, `mail-relay` `10.10.10.12` |
| 20 | Data | `db-postgres` `10.10.20.10`, `mail-data` `10.10.20.12` |
| 30 | Travail | runner GitHub self-hosted, installe manuellement |
| 40 | Supervision / IA | `grafana` `10.10.40.10`, `ollama-ia` `10.10.40.11` |
| 90 | Management | Proxmox et administration |
| 99 | Backup | `backup` `10.10.99.10` |

### Flux principaux

- Internet vers DMZ selon les regles du firewall.
- `mail-relay` vers `mail-data` en SMTP.
- `mail-data` vers `db-postgres` pour les comptes mail virtuels.
- runner GitHub vers Proxmox pour Terraform.
- runner GitHub vers les conteneurs pour Ansible.
- `backup` vers `db-postgres` et `mail-data` pour collecter les sauvegardes.
- `db-postgres` et `mail-data` vers `backup` pour restaurer les donnees si le stockage local est vide.
- supervision et IA isolees dans le VLAN 40.

## Services

| Machine | Role |
|---|---|
| `web-apache` | Apache, Roundcube et point web interne |
| `mail-relay` | Postfix relais SMTP, Rspamd |
| `mail-data` | Postfix, Dovecot, boites mail virtuelles |
| `db-postgres` | PostgreSQL, comptes et alias mail |
| `grafana` | Prometheus, Grafana, dashboards et alertes |
| `ollama-ia` | serveur IA / analyse |
| `backup` | sauvegardes PostgreSQL et mails |

## Prerequis

### Proxmox

- un noeud Proxmox joignable depuis le runner ou le poste d'administration
- un bridge VLAN-aware, par defaut `vmbr0`
- le template LXC configure dans `infra/terraform/terraform.tfvars`
- un utilisateur Proxmox dedie a Terraform

### Poste d'administration ou runner

- Terraform
- Ansible
- acces reseau vers Proxmox et les VLANs prives
- cle SSH privee correspondant a la cle publique injectee par Terraform

## Methode 1 - Installation manuelle

Cette methode lance Terraform et Ansible depuis un poste d'administration.

### Variables Terraform

```bash
cd infra/terraform
cp terraform.tfvars.example terraform.tfvars
```

Exemple de contenu :

```hcl
proxmox_url      = "https://192.168.160.100:8006/api2/json"
proxmox_user     = "terraform@pve"
proxmox_password = "change-me"
proxmox_node     = "proxmox"
proxmox_storage  = "local-lvm"
proxmox_bridge   = "vmbr0"
deploy_backup   = true
ssh_public_key   = "ssh-ed25519 AAAA..."
```

`terraform.tfvars` est ignore par Git.

Les conteneurs principaux sont toujours deployes : web, relais mail, base de donnees, serveur mail interne, supervision et IA.

Seul `deploy_backup` reste optionnel. `deploy_backup = false` permet de deployer le reste de l'infrastructure sans creer le serveur backup. Sur une infrastructure deja creee, passer `deploy_backup` a `false` prepare normalement une suppression Terraform si le backup est deja dans le state. Le workflow GitHub Actions bloque ce cas afin d'eviter une suppression accidentelle.

### Creation des conteneurs

```bash
terraform init
terraform plan -out=plan.tfplan
terraform apply plan.tfplan
```

Terraform injecte uniquement une cle SSH publique dans les conteneurs. Aucun mot de passe root de conteneur n'est stocke dans le depot.

### Variables Ansible locales

```bash
cd ../..
cp ansible/group_vars/all.yml.example ansible/group_vars/all.yml
cp ansible/group_vars/mail.yml.example ansible/group_vars/mail.yml
ansible-vault encrypt ansible/group_vars/mail.yml
```

`all.yml` contient la cle publique des comptes d'administration. `mail.yml` contient les variables sensibles mail et base de donnees.

### Execution Ansible

```bash
cd ansible
ansible-galaxy collection install -r requirements.yml
ansible-playbook -i inventory.ini playbooks/site.yml --ask-vault-pass
```

Ansible cree les utilisateurs d'administration, installe les services et applique les configurations applicatives.

## Methode 2 - Installation par GitHub Actions

Cette methode utilise le workflow manuel `Deploy with Self-Hosted Runner`.

Le runner GitHub Actions n'est pas cree par Terraform. Il est installe manuellement sur une machine interne capable de joindre Proxmox et les VLANs prives, par exemple dans le VLAN 30.

### Installation du runner

1. GitHub repository `Settings` -> `Actions` -> `Runners`.
2. `New self-hosted runner`.
3. Choix `Linux x64`.
4. Execution des commandes affichees par GitHub sur la machine interne.

Le depot ne fournit pas de script custom d'installation du runner. Les commandes officielles GitHub restent la reference.

### Preparation du state Terraform

Le workflow utilise par defaut :

```text
/srv/logistia/terraform/terraform.tfstate
```

Sur la machine du runner :

```bash
sudo mkdir -p /srv/logistia/terraform
sudo chown -R git:git /srv/logistia
```

Si l'utilisateur du runner n'est pas `git`, le proprietaire du dossier correspond a cet utilisateur.

Le chemin du state peut etre remplace par une variable GitHub Actions :

```text
TERRAFORM_STATE_PATH=/srv/logistia/terraform/terraform.tfstate
```

### Secrets GitHub Actions

Les secrets sont configures dans `Settings` -> `Secrets and variables` -> `Actions`.

| Secret | Description |
|---|---|
| `PROXMOX_URL` | URL Proxmox, ex. `https://192.168.160.100:8006/api2/json` |
| `PROXMOX_USER` | utilisateur Proxmox utilise par Terraform |
| `PROXMOX_PASSWORD` | mot de passe ou secret associe a l'utilisateur Proxmox |
| `SSH_PUBLIC_KEY` | cle publique injectee dans les conteneurs |
| `ANSIBLE_SSH_PRIVATE_KEY` | cle privee correspondant a `SSH_PUBLIC_KEY` |
| `ANSIBLE_MAIL_VARS` | variables mail et PostgreSQL au format YAML |

Exemple de valeur pour `ANSIBLE_MAIL_VARS` :

```yaml
mail_domain: logistia.prod
mail_relay_ip: 10.10.10.12
mail_backend_ip: 10.10.20.12
mail_backend_hostname: mail-data
mail_relay_hostname: mail-relay

db_host: 10.10.20.10
db_port: 5432
db_name: mailserver
db_user: mailuser
db_password: "replace-with-a-strong-database-password"
db_mail_allowed_cidr: 10.10.20.0/24
db_web_allowed_cidr: 10.10.10.0/24

roundcube_db_name: roundcube
roundcube_db_user: roundcubeuser
roundcube_db_password: "replace-with-a-strong-roundcube-db-password"
roundcube_des_key: "replace-with-24-random-characters"
roundcube_imap_host: "ssl://10.10.20.12:993"
roundcube_smtp_host: "10.10.10.12"
roundcube_smtp_port: 25

postfixadmin_enabled: false
postfixadmin_setup_password_hash: ""

mail_vhost_base: /var/mail/vhosts
vmail_uid: 5000
vmail_gid: 5000

mail_users:
  - email: arthur@logistia.prod
    password: "replace-with-a-strong-password"
  - email: celia@logistia.prod
    password: "replace-with-a-strong-password"
  - email: christopher@logistia.prod
    password: "replace-with-a-strong-password"
  - email: norada@logistia.prod
    password: "replace-with-a-strong-password"

mail_aliases:
  - source: admin@logistia.prod
    destination: arthur@logistia.prod
```

Les mots de passe mail sont haches en `SHA512-CRYPT` dans PostgreSQL par Ansible. `db_password` reste uniquement dans les secrets GitHub ou dans le fichier local chiffre.

Roundcube est installe sur le conteneur web et utilise la base `roundcube`. PostfixAdmin est present dans le role web mais reste desactive par defaut, car son schema SQL n'est pas encore celui utilise par Postfix et Dovecot dans ce projet.

Les logs mail sont envoyes vers le conteneur IA. Le workflow genere `mail_log_forwarding_enabled`, `mail_log_ai_host` et `mail_log_ai_port` dans `group_vars/all.yml`.

### Execution du workflow

Le workflow se lance depuis `Actions` -> `Deploy with Self-Hosted Runner` -> `Run workflow`.

Options disponibles :

| Option | Effet |
|---|---|
| `terraform_action = plan` | execute uniquement le plan Terraform |
| `terraform_action = apply` | applique le plan Terraform |
| `run_ansible = true` | lance Ansible apres Terraform |
| `run_ansible = false` | limite l'execution a Terraform |
| `deploy_backup = true` | cree et configure le serveur backup |
| `deploy_backup = false` | exclut le serveur backup du deploiement |

Le detail des jobs, des commandes executees et de la procedure de rollback est documente dans [.github/workflows/README.md](.github/workflows/README.md).

Le workflow bloque `deploy_backup = false` si le conteneur backup est deja present dans le state Terraform. Ce garde-fou evite de planifier accidentellement la suppression des sauvegardes.

## Acces SSH

Avant le passage Ansible, l'acces s'effectue avec `root` et la cle injectee par Terraform :

```bash
ssh -i ~/.ssh/logistia_ed25519 root@10.10.10.10
```

Apres le passage Ansible, les comptes d'administration correspondent aux noms des machines :

```bash
ssh -i ~/.ssh/logistia_ed25519 web-apache@10.10.10.10
ssh -i ~/.ssh/logistia_ed25519 db-postgres@10.10.20.10
ssh -i ~/.ssh/logistia_ed25519 mail-data@10.10.20.12
ssh -i ~/.ssh/logistia_ed25519 mail-relay@10.10.10.12
ssh -i ~/.ssh/logistia_ed25519 grafana@10.10.40.10
ssh -i ~/.ssh/logistia_ed25519 ollama-ia@10.10.40.11
ssh -i ~/.ssh/logistia_ed25519 backup@10.10.99.10
```

Lorsque les VLANs ne sont pas accessibles depuis le poste, l'acces passe par le reseau d'administration, Proxmox ou une machine rebond autorisee.

## Structure du depot

```text
.
|-- .github/
|   |-- ACTIONS.md
|   `-- workflows/
|       |-- ci-cd.yml
|       |-- deploy-with-self-hosted-runner.yml
|       `-- README.md
|-- ansible/
|   |-- ansible.cfg
|   |-- inventory.ini
|   |-- requirements.yml
|   |-- group_vars/
|   |-- playbooks/
|   `-- roles/
`-- infra/
    |-- README.md
    `-- terraform/
        |-- main.tf
        |-- variables.tf
        |-- outputs.tf
        |-- terraform.tfvars.example
        `-- modules/
```

## Documentation par dossier

| Dossier | Documentation |
|---|---|
| `.github/` | [automatisation GitHub Actions](.github/ACTIONS.md) |
| `.github/workflows/` | [details des workflows CI et deploiement](.github/workflows/README.md) |
| `infra/` | [separation Terraform / Ansible](infra/README.md) |
| `infra/terraform/` | [commandes Terraform et choix d'infrastructure](infra/terraform/README.md) |
| `infra/terraform/modules/` | [principe des modules Terraform](infra/terraform/modules/README.md) |
| `infra/terraform/modules/vm/` | [module de creation des conteneurs LXC](infra/terraform/modules/vm/README.md) |
| `ansible/` | [fonctionnement general Ansible](ansible/README.md) |
| `ansible/playbooks/` | [ordre d'execution du playbook](ansible/playbooks/README.md) |
| `ansible/group_vars/` | [variables, secrets et exemples](ansible/group_vars/README.md) |
| `ansible/roles/` | [roles applicatifs et choix techniques](ansible/roles/README.md) |

## Securite

- Les fichiers `terraform.tfvars`, `terraform.tfstate`, `.terraform/` et les vrais fichiers `ansible/group_vars/*.yml` sont ignores par Git.
- Les secrets GitHub Actions remplacent les fichiers locaux dans le workflow de deploiement.
- Terraform injecte une cle SSH publique et ne stocke pas de mot de passe root de conteneur.
- Le runner self-hosted reste interne au reseau et n'est pas cree par Terraform.
- Le state Terraform est conserve hors depot, sur un chemin persistant du runner.
- Les flux entre VLANs sont controles par le firewall/routeur de l'infrastructure.
