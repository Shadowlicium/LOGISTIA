# Role web

Ce role configure le conteneur `web-apache`.

Il installe Apache, PHP, Roundcube et les dependances necessaires pour acceder au serveur mail interne.

## Roundcube

Roundcube est active par defaut avec `roundcube_enabled: true`.

Le role utilise les variables de `ANSIBLE_MAIL_VARS` :

- `roundcube_db_user`
- `roundcube_db_password`
- `roundcube_db_name`
- `roundcube_des_key`
- `roundcube_imap_host`
- `roundcube_smtp_host`
- `roundcube_smtp_port`

Le fichier `/etc/roundcube/config.inc.php` est genere avec des permissions restrictives et la tache est marquee `no_log` pour eviter l'affichage des secrets.

Le schema PostgreSQL Roundcube est initialise une seule fois. Le role teste la presence de la table `users` avant d'executer le script SQL fourni par le paquet Roundcube.

## Plugin 2FA

Le plugin `twofactor_gauthenticator` est installe depuis GitHub quand `roundcube_twofactor_plugin_enabled: true`.

La version utilisee est controlee par `roundcube_twofactor_plugin_version`. La valeur par defaut est `master`, car le plugin fourni par le collaborateur fonctionne de cette maniere. Pour un environnement plus strict, cette variable peut pointer vers un tag ou un commit.

## PostfixAdmin

PostfixAdmin est prepare dans le role mais desactive par defaut avec `postfixadmin_enabled: false`.

La raison est importante : le projet utilise deja un schema PostgreSQL maison pour les comptes virtuels (`mail_domains`, `mail_users`, `mail_aliases`), alors que PostfixAdmin attend son propre schema. L'activer sans aligner les requetes Postfix/Dovecot ne permettrait pas de gerer correctement les comptes mail existants.

Quand le schema est aligne, l'activation se fait avec :

```yaml
postfixadmin_enabled: true
postfixadmin_setup_password_hash: "hash-genere-par-postfixadmin"
```
