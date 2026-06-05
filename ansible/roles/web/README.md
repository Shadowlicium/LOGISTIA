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

Le projet peut utiliser le schema PostfixAdmin avec `mail_schema: postfixadmin`. Dans ce mode, Postfix et Dovecot lisent les tables `domain`, `mailbox` et `alias`, les memes tables que PostfixAdmin administre.

L'activation se fait avec :

```yaml
mail_schema: postfixadmin
postfixadmin_enabled: true
postfixadmin_setup_password_hash: "hash-genere-par-postfixadmin"
```

`postfixadmin_password_scheme` vaut `php_crypt:SHA512` par defaut afin de generer des mots de passe compatibles avec Dovecot.
