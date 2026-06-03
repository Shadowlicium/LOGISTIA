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
8. backup

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

## Pourquoi `serial: 1` sur le role users

Le premier play applique le role `users` avec `serial: 1`. Les conteneurs sont donc traites un par un.

Ce choix rend le premier passage plus lisible et evite plusieurs installations APT simultanees au moment ou les machines viennent juste d'etre creees.

## Pourquoi `become: yes`

Les roles installent des paquets, modifient `/etc`, creent des utilisateurs et redemarrent des services. Ces operations demandent les droits root.

`become: yes` indique a Ansible d'executer les taches avec les privileges necessaires.
