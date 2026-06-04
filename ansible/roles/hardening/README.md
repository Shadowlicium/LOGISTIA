# Role hardening

Ce role applique le durcissement systeme commun aux conteneurs LOGISTIA.

Il est execute a la fin du playbook, apres l'installation des services applicatifs.

Ce choix laisse chaque machine telecharger et installer ses paquets applicatifs avant le durcissement final. Le role `users` reste execute au debut pour garder l'acces SSH par cle des le premier passage.

## Choix de securite

Le role reste volontairement compatible avec des conteneurs LXC. Il evite les reglages trop proches du noyau ou du firewall local, car ces points sont geres par Proxmox, le routeur/firewall et les VLANs.

## Taches appliquees

| Tache | Raison |
|---|---|
| installation de `fail2ban` et `python3-systemd` | bloquer les tentatives SSH repetees via les logs systemd |
| installation de `unattended-upgrades` | appliquer automatiquement les mises a jour de securite |
| options SSH supplementaires | reduire les surfaces inutiles comme X11 et les methodes clavier interactives |
| limites journald | garder des logs persistants sans remplir le disque |
| sysctl reseau | refuser les redirections et routes source quand le conteneur l'autorise |

## Variables principales

| Variable | Valeur par defaut | Effet |
|---|---|---|
| `hardening_enable_fail2ban` | `true` | active la protection SSH fail2ban |
| `hardening_enable_unattended_upgrades` | `true` | active les mises a jour automatiques |
| `hardening_manage_sysctl` | `true` | applique les reglages reseau |
| `hardening_manage_journald` | `true` | configure la retention des logs |
| `hardening_manage_sshd_extra` | `true` | ajoute les options SSH supplementaires |

Les variables sont dans `defaults/main.yml`, donc elles peuvent etre surchargees depuis `group_vars/all.yml` si une machine a besoin d'un comportement different.
