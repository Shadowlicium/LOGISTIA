# Playbooks Ansible

Ce dossier contient le point d'entree Ansible du projet.

`site.yml` applique tous les roles dans un ordre controle.

## Pourquoi un playbook principal

Un playbook principal evite de lancer manuellement chaque role. Il decrit l'ordre logique de configuration :

1. securisation et utilisateurs sur tous les conteneurs
2. serveur web
3. base de donnees
4. supervision
5. relais mail
6. serveur mail interne
7. IA
8. forwarding des logs mail vers l'IA
9. backup centralise
10. client de restauration backup sur DB et mail
11. hardening systeme commun
12. exporters Prometheus sur les conteneurs
13. Grafana, Prometheus, dashboards et alertes

## Commande de verification

```bash
ANSIBLE_ROLES_PATH=roles ansible-playbook -i inventory.ini --syntax-check playbooks/site.yml
```

Cette commande ne se connecte pas aux machines. Elle verifie uniquement la structure Ansible.

## Commande d'application

```bash
ansible-playbook -i inventory.ini playbooks/site.yml
```

Cette commande se connecte aux machines et applique les roles.

## Pourquoi `serial: 1` sur users et hardening

Le role `users` et le role final `hardening` utilisent `serial: 1`. Les conteneurs sont donc traites un par un pour ces etapes sensibles.

Ce choix rend le premier passage plus lisible, evite plusieurs installations APT simultanees au moment ou les machines viennent juste d'etre creees, puis applique le durcissement final machine par machine.

## Pourquoi backup est applique avant backup_client

Le role `backup` prepare le serveur central, cree sa cle SSH de collecte et installe les timers.

Le role `backup_client` passe ensuite sur `db-postgres` et `mail-data`. Il autorise la cle du serveur backup a lire les donnees, puis cree les scripts de restauration prudente au demarrage.

Cet ordre evite de configurer des clients qui pointeraient vers un serveur backup pas encore initialise.

## Pourquoi Grafana est applique apres monitoring_exporter

Le role `monitoring_exporter` installe `prometheus-node-exporter` sur les conteneurs et expose les metriques CPU, RAM, disque, mail et securite.

Le role `grafana` est applique ensuite sur le conteneur de supervision. Il installe Prometheus, configure les targets, ajoute la datasource Grafana, cree les dashboards et charge les regles d'alerte.

Cet ordre evite que Prometheus demarre avec des targets qui n'existent pas encore.

## Pourquoi les logs mail sont envoyes apres l'IA

Le role `ollama` prepare le fichier de reception et la configuration rsyslog TCP sur le conteneur IA.

Le role `mail_log_forwarder` est applique ensuite sur `mail-relay` et `mail-data`. Il configure rsyslog pour envoyer les logs `mail.*` vers l'IA, ce qui permet a l'analyseur de lire les evenements SMTP, Rspamd, Postfix et Dovecot depuis un point central.

## Pourquoi `become: yes`

Les roles installent des paquets, modifient `/etc`, creent des utilisateurs et redemarrent des services. Ces operations demandent les droits root.

`become: yes` indique a Ansible d'executer les taches avec les privileges necessaires.
