# Roles Ansible

Ce dossier contient les roles applicatifs du projet.

Un role Ansible regroupe les taches, handlers, variables par defaut, fichiers et templates d'un service.

## Pourquoi utiliser des roles

Les roles rendent le playbook principal plus lisible. Au lieu d'avoir toutes les taches dans un seul fichier, chaque service garde sa logique dans son propre dossier.

Cela permet aussi de relire ou modifier un service sans toucher au reste de l'infrastructure.

## Roles du projet

| Role | Machine cible | Explication |
|---|---|---|
| `users` | tous les conteneurs geres | cree les comptes d'administration et durcit SSH |
| `hardening` | tous les conteneurs geres | applique le durcissement systeme commun |
| `web` | `web-apache` | installe Apache et une page simple |
| `db` | `db-postgres` | installe PostgreSQL et cree les tables mail |
| `mail_relay` | `mail-relay` | configure Postfix en relais DMZ avec Rspamd |
| `postfix` | `mail-data` | configure Postfix pour les boites virtuelles |
| `dovecot` | `mail-data` | configure IMAP et LMTP avec PostgreSQL |
| `grafana` | `grafana` | installe le service de supervision |
| `ollama` | `ollama-ia` | installe le service IA et l'analyse de logs |
| `backup` | `backup` | prepare les sauvegardes rsync |

## Taches

Les fichiers `tasks/main.yml` decrivent les actions a appliquer :

- installer des paquets avec `apt`
- creer des utilisateurs avec `user`
- ecrire des fichiers avec `copy` ou `template`
- creer des dossiers avec `file`
- demarrer des services avec `service`

Les modules Ansible sont preferes aux commandes shell car ils sont idempotents. Une tache idempotente peut etre relancee sans refaire inutilement la meme action.

## Handlers

Les fichiers `handlers/main.yml` contiennent les redemarrages de services.

Exemple :

```yaml
notify: Restart postfix
```

Une tache notifie un handler seulement si elle modifie un fichier. Cela evite de redemarrer un service quand sa configuration n'a pas change.

## Defaults

Les fichiers `defaults/main.yml` donnent des valeurs par defaut non sensibles.

Les vraies valeurs sensibles viennent de `group_vars/mail.yml` ou des secrets GitHub Actions.

## Templates

Les fichiers `.j2` sont des templates Jinja2. Ils permettent de generer une configuration avec les variables Ansible.

Dans le role `postfix`, les templates PostgreSQL contiennent les parametres de connexion a la base mail. Ils sont deployes avec des permissions restrictives et marques `no_log` dans les taches pour eviter d'afficher les secrets dans les logs.

## Choix hardening

Le role `hardening` applique les mesures communes apres la creation des comptes d'administration :

- fail2ban pour limiter les attaques SSH par essais repetes
- unattended-upgrades pour appliquer les mises a jour de securite
- options SSH supplementaires pour reduire les fonctions inutiles
- limites journald pour garder des logs sans remplir les disques
- reglages sysctl reseau compatibles avec les contraintes LXC

Le firewall local n'est pas configure dans les conteneurs. Les flux sont controles par les VLANs, Proxmox et le routeur/firewall de l'infrastructure.

## Choix mail

Le serveur mail interne utilise des comptes virtuels stockes dans PostgreSQL.

Ce choix evite de creer un compte Linux par adresse mail. Postfix et Dovecot interrogent PostgreSQL pour savoir quels domaines, boites et alias existent.

Les mots de passe sont stockes en `SHA512-CRYPT`, pas en clair.
