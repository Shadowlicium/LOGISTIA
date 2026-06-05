# Role monitoring_exporter

Ce role installe `prometheus-node-exporter` sur les conteneurs geres.

## Metriques collectees

| Type | Source |
|---|---|
| CPU | `node_cpu_seconds_total` |
| RAM | `node_memory_*` |
| disque | `node_filesystem_*` |
| services systemd | collecteur systemd de node_exporter |
| securite | fichier textfile `logistia_security.prom` |
| mail | fichier textfile `logistia_mail.prom` sur `mail-relay` et `mail-data` |

Les metriques textfile permettent d'ajouter des indicateurs simples sans installer un exporter specialise pour chaque service.
