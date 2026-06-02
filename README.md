# LOGISTIA — Infrastructure CI/CD sur Proxmox

**Déploiement automatisé d'une infrastructure multi-services sur Proxmox avec Terraform + Ansible.**

## Architecture

### Services

- **VLAN 10 (DMZ)**
  - `web` (10.10.10.10): Apache web server
  - `mail-relay` (10.10.10.12): relais SMTP avec analyse des mails

- **VLAN 20 (Data)**
  - `db` (10.10.20.10): PostgreSQL
  - `mail-data` (10.10.20.12): serveur mail interne avec Postfix + Dovecot

- **VLAN 40 (Supervision & IA)**
  - `grafana` (10.10.40.10): Monitoring & dashboards
  - `ollama` (10.10.40.11): AI models & log analysis

- **VLAN 30 (CI/CD)**
  - `gh-runner` (10.10.30.10): GitHub Actions self-hosted runner

- **VLAN 99 (Backup)**
  - `backup` (10.10.99.10): Rsync backup service

### Stack

- **Terraform**: Crée les conteneurs LXC sur Proxmox avec IP fixes, vLANs, ressources
- **Ansible**: Configure et déploie les services sur chaque VM
- **GitHub Actions**: Pipeline CI/CD pour linting, planning, et logs

## Démarrage rapide

### Prérequis

1. Proxmox accessible via API
2. Accès VPN à ton réseau (ou tunnel SSH)
3. Clé SSH publique pour injection dans les VMs
4. Terraform installé localement (>= 1.0)
5. Ansible installé localement (>= 2.12)

### Phase 1 : Configuration

1. **Clone le dépôt** et crée ton fichier Terraform local:

```bash
cd infra/terraform
cp terraform.tfvars.example terraform.tfvars
# Édite terraform.tfvars avec tes vraies valeurs.
# Ce fichier est ignoré par Git.
```

2. **Crée les variables Ansible locales**:

```bash
cd ../..
cp ansible/group_vars/all.yml.example ansible/group_vars/all.yml
cp ansible/group_vars/mail.yml.example ansible/group_vars/mail.yml
ansible-vault encrypt ansible/group_vars/mail.yml
```

3. **Configure ta clé SSH locale pour Ansible**:

```bash
# La clé privée doit correspondre à ssh_public_key dans terraform.tfvars.
ssh-add ~/.ssh/id_ed25519
```

4. **Configure l'inventaire Ansible** si les IPs diffèrent:

```bash
# Édite ansible/inventory.ini avec les bonnes adresses IP
```

### Phase 2 : Créer l'Infrastructure

1. **Planifier le déploiement**:

```bash
cd infra/terraform
terraform init
terraform plan -out=plan.tfplan
```

2. **Appliquer le plan** (depuis une machine avec accès Proxmox/VPN):

```bash
terraform apply plan.tfplan
```

Une fois les conteneurs créés, attends quelques secondes pour que l'initialisation finisse.

### Phase 3 : Configurer les Services

Exécute Ansible depuis ta machine avec accès VPN:

```bash
ansible-playbook -i ansible/inventory.ini ansible/playbooks/site.yml
```

Si `ansible/group_vars/mail.yml` est chiffré avec Ansible Vault:

```bash
ansible-playbook -i ansible/inventory.ini ansible/playbooks/site.yml --ask-vault-pass
```

Cela va :
- Installer et configurer Apache, PostgreSQL, Grafana, le relay mail, le serveur mail interne, Ollama, etc.
- Créer un utilisateur d'administration par machine avec une clé SSH
- Créer les utilisateurs mail définis dans tes variables Ansible locales
- Configurer les certificats SSL auto-signés
- Démarrer tous les services

### Phase 4 : Installer le GitHub Runner (Optional)

Si tu veux que les workflows s'exécutent automatiquement dans ton réseau:

1. **SSH vers la VM runner**:

```bash
ssh root@10.10.30.10
```

2. **Lance le script d'installation**:

```bash
export GITHUB_OWNER=your-username
export GITHUB_REPO=LOGISTIA
export RUNNER_TOKEN=replace-with-runner-token
/opt/github-runner/install-github-runner.sh
```

Voir [ansible/roles/runner/README.md](ansible/roles/runner/README.md) pour les détails complets.

## Structure du dépôt

```
.
├── README.md                          # Ce fichier
├── .github/
│   └── workflows/ci-cd.yml            # Pipeline GitHub Actions
├── infra/
│   └── terraform/
│       ├── main.tf                    # Configuration des VMs
│       ├── variables.tf               # Variables d'entrée
│       ├── outputs.tf                 # Sorties du déploiement
│       └── modules/vm/                # Module réutilisable pour chaque VM
└── ansible/
    ├── inventory.ini                  # Inventaire (adresses IPs des VMs)
    ├── playbooks/site.yml             # Playbook principal
    └── roles/
        ├── web/                       # Apache web server
        ├── db/                        # PostgreSQL
        ├── grafana/                   # Grafana monitoring
        ├── mail_relay/                # Relais SMTP DMZ avec analyse Rspamd
        ├── postfix/                   # Postfix interne pour stockage mail
        ├── dovecot/                   # Mail interne (IMAP/POP3/LMTP)
        ├── ollama/                    # AI models & log analysis
        ├── runner/                    # GitHub Actions runner
        └── backup/                    # Rsync backups
```

## Services & Configuration

### Web Server (Apache)

- Écoute sur `10.10.10.10:80`
- Page d'accueil simple à personnaliser

### Mail Relay & Mail Server

Le mail est séparé en deux zones :

- `mail-relay` en DMZ (`10.10.10.12`) reçoit le SMTP, analyse les messages avec Rspamd, puis relaie uniquement le domaine configuré vers le serveur interne.
- `mail-data` en data (`10.10.20.12`) stocke les boîtes mail avec Postfix + Dovecot et accepte le SMTP depuis le relay DMZ.

**Utilisateurs mail**:
Les comptes sont définis dans `ansible/group_vars/mail.yml`, fichier local ignoré par Git et prévu pour être chiffré avec Ansible Vault.

**Flux réseau**:
- SMTP entrant: `mail-relay:25`
- Analyse: Rspamd via milter local sur le relay
- Transfert interne: `mail-relay` -> `mail-data:25`
- Accès utilisateurs: IMAP/POP3 TLS sur `mail-data`

**Note**: Aucun mot de passe réel ne doit être commité. Le dépôt fournit seulement `ansible/group_vars/mail.yml.example`.

### Database (PostgreSQL)

PostgreSQL est installé mais la base et les utilisateurs doivent être créés manuellement ou via un rôle Ansible amélioré.

### Monitoring (Grafana)

- Accès par défaut: `http://10.10.40.10:3000` (admin/admin)
- À configurer avec des datasources (Prometheus, etc.)

### AI (Ollama)

- Installe Python + un service de log analysis
- Exécute une tâche toutes les 5 minutes via systemd timer

### Backup

- Sauvegarde `/var/www/` vers `/backup/` via rsync
- Cron job à 2h du matin chaque jour

## GitHub Actions Workflow

Le workflow `.github/workflows/ci-cd.yml` effectue :

1. **Lint**: Terraform format check + Ansible syntax check
2. **Terraform Validate**: initialise Terraform sans backend distant et valide la configuration
3. **Security Scan**: Trivy filesystem scan

> **Note** : Comme l'infrastructure est privée (VPN), `terraform apply` et le déploiement Ansible doivent être exécutés manuellement ou via le self-hosted runner.

## Dépannage

### Terraform ne se connecte pas à Proxmox

- Vérifie que `proxmox_url`, `proxmox_user`, `proxmox_password` sont corrects
- Teste la connexion : `curl -k https://proxmox.example.com:8006/api2/json/version`
- Vérifie que tu es connecté au VPN

### Ansible ne peut pas SSH sur les VMs

- Vérifie que l'inventaire contient les bonnes adresses IP
- Test : `ssh -i /path/to/key root@10.10.10.10`
- Assure-toi que la clé SSH publique est injectée dans les VMs (voir `ssh_public_key` dans variables.tf)
- Après le premier passage Ansible, tu peux aussi tester l'utilisateur de la machine : `ssh web-apache@10.10.10.10`

### Secrets GitHub nécessaires au runner self-hosted

Pour le workflow `.github/workflows/deploy-with-self-hosted-runner.yml`, configure ces secrets dans GitHub:

- `PROXMOX_URL`, `PROXMOX_USER`, `PROXMOX_PASSWORD`
- `SSH_PUBLIC_KEY`: clé publique injectée par Terraform dans les conteneurs
- `ANSIBLE_SSH_PRIVATE_KEY`: clé privée correspondante, utilisée par le runner pour se connecter en SSH
- `ANSIBLE_MAIL_VARS`: contenu YAML des variables mail, avec les mots de passe des comptes

### Les services ne démarrent pas

- Vérifie les logs Ansible
- SSH sur la VM concernée et vérifie le service : `systemctl status postfix`, etc.
- Logs : `journalctl -u postfix -n 50`

### Le GitHub runner ne se connecte pas

- Vérifie le token de registration (expire après 8h)
- Logs : `journalctl -u actions.runner.* -f`
- Assure-toi que la VM a accès à `api.github.com` sur HTTPS

## Prochaines étapes

- [ ] Personnaliser les pages web
- [ ] Configurer des datasources Grafana (Prometheus, Loki, etc.)
- [ ] Créer les bases PostgreSQL et utilisateurs
- [ ] Déplacer le state Terraform vers un backend distant chiffré
- [ ] Ajouter des métriques et alertes dans Grafana
- [ ] Configurer un backup distant (S3, NFS, etc.)
- [ ] Tests d'intégration GitHub Actions sur le runner self-hosted

## Licence

Voir LICENSE (si applicable)
