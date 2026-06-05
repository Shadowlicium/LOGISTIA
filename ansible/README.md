# Ansible LOGISTIA

Ce dossier configure les conteneurs crees par Terraform.

Terraform prepare les machines. Ansible se connecte ensuite en SSH et installe les services.

## Structure

| Element | Role |
|---|---|
| `ansible.cfg` | configuration Ansible locale |
| `inventory.ini` | liste des machines et groupes |
| `requirements.yml` | collections Ansible externes |
| `group_vars/` | variables par groupe |
| `playbooks/site.yml` | ordre d'application des roles |
| `roles/` | configurations applicatives |

## Configuration Ansible

`ansible.cfg` contient :

```ini
[defaults]
inventory = inventory.ini
roles_path = roles
host_key_checking = False
retry_files_enabled = False
```

`inventory = inventory.ini` evite de fournir `-i inventory.ini` a chaque commande.

`roles_path = roles` indique que les roles sont dans `ansible/roles`.

`host_key_checking = False` evite un blocage au premier contact SSH avec les conteneurs recrees par Terraform. Ce choix facilite le lab, mais dans un environnement de production les empreintes SSH seraient gerees plus strictement.

`retry_files_enabled = False` evite de creer des fichiers `.retry` inutiles dans le depot.

## Inventaire

`inventory.ini` groupe les machines par fonction :

- `webservers`
- `mail_relays`
- `mailservers`
- `databases`
- `monitoring`
- `ai`
- `backups`

Les groupes comme `managed_containers` permettent de lancer une action sur tous les conteneurs geres, sans inclure Proxmox.

Chaque hote utilise `ansible_user=root` au premier passage, car Terraform injecte la cle SSH publique dans root. Le role `users` cree ensuite un utilisateur d'administration propre a chaque machine.

## Collections

La commande suivante installe les collections externes :

```bash
ansible-galaxy collection install -r requirements.yml
```

Le projet utilise `community.postgresql` pour gerer PostgreSQL avec des modules Ansible dedies plutot qu'avec des commandes SQL brutes partout.

## Syntax-check

```bash
ANSIBLE_ROLES_PATH=roles ansible-playbook -i inventory.ini --syntax-check playbooks/site.yml
```

Cette commande verifie que le playbook est lisible par Ansible et que les roles references existent.

`ANSIBLE_ROLES_PATH=roles` rend la commande robuste lorsque `ansible.cfg` est ignore, par exemple dans certains montages WSL ou dossiers avec permissions larges.

## Execution

```bash
ansible-playbook -i inventory.ini playbooks/site.yml
```

Cette commande applique tous les roles dans l'ordre du playbook.

Le pipeline GitHub Actions genere temporairement les fichiers sensibles dans `group_vars/` a partir des secrets GitHub, puis lance cette meme commande.

## Pourquoi les roles sont separes

Chaque role a une responsabilite :

- `users` securise l'acces SSH et cree les comptes d'administration.
- `hardening` applique le durcissement systeme commun.
- `web` installe Apache, Roundcube et prepare PostfixAdmin.
- `db` configure PostgreSQL pour les comptes mail virtuels.
- `db_logistia` configure la base metier du portail LOGISTIA.
- `mail_relay` configure le relais Postfix en DMZ avec Rspamd.
- `postfix` configure le serveur mail interne.
- `dovecot` configure l'acces IMAP et LMTP.
- `mail_log_forwarder` envoie les logs mail vers le conteneur IA pour analyse.
- `backup` centralise les sauvegardes PostgreSQL et mail.
- `backup_client` prepare la restauration prudente sur `db-postgres` et `mail-data`.
- `monitoring_exporter` expose les metriques CPU, RAM, disque, mail et securite.
- `grafana` installe Grafana, Prometheus, dashboards et alertes.
- `ollama` configure le service IA de sa zone.

Cette separation rend les erreurs plus faciles a isoler et permet de relancer un role sans relire tout le projet.
