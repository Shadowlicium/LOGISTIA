# Dossier infra

Ce dossier contient la partie infrastructure-as-code du projet LOGISTIA.

Il separe la creation des machines de leur configuration applicative :

- `terraform/` cree les conteneurs LXC sur Proxmox.
- Ansible, dans le dossier racine `ansible/`, configure ensuite les services.

## Pourquoi Terraform est separe d'Ansible

Terraform decrit l'etat attendu de l'infrastructure : noms des machines, VMID, IP, disque, RAM, bridge, passerelle et cle SSH injectee.

Ansible decrit l'etat attendu dans les machines : paquets installes, fichiers de configuration, services demarres, utilisateurs et securisation SSH.

Cette separation evite de melanger deux responsabilites :

- Terraform sait creer ou modifier les conteneurs.
- Ansible sait configurer les systemes une fois qu'ils repondent en SSH.

## Comment le deploiement s'enchaine

1. Terraform contacte l'API Proxmox.
2. Terraform cree ou met a jour les conteneurs LXC.
3. Terraform injecte la cle SSH publique dans le compte root des conteneurs.
4. Ansible attend que les conteneurs soient accessibles en SSH.
5. Ansible installe les roles applicatifs.
6. Le role `users` cree ensuite les comptes d'administration par machine.

## Choix de securite

Les mots de passe ne sont pas stockes dans ce dossier. Les variables sensibles sont fournies localement par `terraform.tfvars` ou par les secrets GitHub Actions.

Le state Terraform n'est pas versionne. Il represente l'etat reel connu de l'infrastructure et peut contenir des informations sensibles.
