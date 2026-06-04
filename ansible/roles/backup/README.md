# Role backup

Ce role configure le serveur central de sauvegarde.

Il est applique uniquement sur le groupe `backups`.

## Donnees sauvegardees

| Source | Methode | Destination |
|---|---|---|
| `db-postgres` | `pg_dumpall` via SSH | `/backup/postgres/dumps/` |
| `mail-data` | `rsync` de `/var/vmail` | `/backup/mail-data/current/` et snapshots |

## Fonctionnement

Le serveur backup genere une cle SSH locale dans `/root/.ssh/logistia_backup_ed25519`.

Le role `backup_client` autorise ensuite cette cle sur `db-postgres` et `mail-data`. Le serveur backup peut alors tirer les donnees sans stocker de mot de passe.

La sauvegarde est lancee par `logistia-backup.timer`. Par defaut, elle s'execute toutes les 30 minutes.

## Retention

| Variable | Valeur par defaut | Effet |
|---|---|---|
| `backup_retention_days` | `14` | duree de retention des dumps PostgreSQL |
| `backup_snapshot_retention_days` | `7` | duree de retention des snapshots mail |
| `backup_timer_on_calendar` | `*:0/30` | frequence systemd du timer |

## Securite

Les sauvegardes restent dans `/backup`, hors depot Git.

Le role ne contient aucun mot de passe. Les acces se font par cles SSH generees sur les machines.
