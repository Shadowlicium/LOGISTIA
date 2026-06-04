# Role backup_client

Ce role prepare les machines sources qui doivent etre sauvegardees ou restaurees.

Il est applique sur `db-postgres` et `mail-data`.

## Sur les sources

Le role autorise la cle publique du serveur backup sur root. Cela permet au serveur backup de lire :

- PostgreSQL sur `db-postgres` avec `pg_dumpall`
- `/var/vmail` sur `mail-data` avec `rsync`

## Restauration au demarrage

Chaque source genere aussi une cle de restauration locale. Cette cle est autorisee sur le serveur backup.

Les services suivants sont installes :

- `logistia-restore-postgres.service` sur `db-postgres`
- `logistia-restore-mail.service` sur `mail-data`

Par defaut, ces services sont actives au demarrage, mais ils restent prudents :

- PostgreSQL n'est restaure que si la table mail principale n'existe pas ;
- les mails ne sont restaures que si `/var/vmail` est vide ;
- un fichier force peut etre cree pour declencher une restauration volontaire.

Le fichier force par defaut est :

```text
/var/lib/logistia-backup/force-restore
```

## Variables

| Variable | Valeur par defaut | Effet |
|---|---|---|
| `backup_enabled` | `true` | active les roles backup |
| `backup_restore_on_boot` | `true` | active les services de restauration au demarrage |
| `backup_restore_force_file` | `/var/lib/logistia-backup/force-restore` | fichier permettant une restauration forcee |
