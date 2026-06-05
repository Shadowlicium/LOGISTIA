# Role grafana

Ce role installe la supervision centrale sur le conteneur `grafana`.

## Services installes

| Service | Role |
|---|---|
| Prometheus | collecte les metriques des conteneurs |
| Grafana | affiche les dashboards et gere les alertes |

## Provisioning

Le role cree automatiquement :

- la datasource Prometheus ;
- le dashboard `LOGISTIA - Infrastructure` ;
- le dashboard `LOGISTIA - Mail` ;
- le dashboard `LOGISTIA - Securite` ;
- les regles d'alertes Grafana.

Ces fichiers sont places dans `/etc/grafana/provisioning/` et `/var/lib/grafana/dashboards/`.

## Alertes

| Alerte | Seuil par defaut |
|---|---|
| CPU elevee | 85% |
| RAM elevee | 85% |
| disque racine eleve | 85% |
| queue mail | 20 messages |
| fail2ban ban actif | plus de 0 |

Les seuils sont dans `defaults/main.yml` et peuvent etre surcharges depuis `group_vars/all.yml`.
