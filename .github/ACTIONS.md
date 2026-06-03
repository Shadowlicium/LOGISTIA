# Automatisation GitHub

Ce dossier contient l'automatisation GitHub du projet.

Les workflows GitHub Actions servent a valider le code et a deployer l'infrastructure depuis un runner interne.

## Pourquoi deux workflows

Le projet separe la validation du deploiement :

- `ci-cd.yml` verifie le code a chaque push ou pull request.
- `deploy-with-self-hosted-runner.yml` deploie manuellement depuis le runner interne.

Cette separation evite qu'un simple push modifie l'infrastructure Proxmox sans action volontaire.

## Pourquoi un runner self-hosted

Les conteneurs et Proxmox ne sont pas exposes publiquement. Un runner GitHub heberge par GitHub ne peut donc pas joindre les VLANs prives.

Le runner self-hosted est place dans le reseau interne. Il peut contacter :

- l'API Proxmox pour Terraform
- les conteneurs en SSH pour Ansible

Les secrets GitHub fournissent les identifiants et cles necessaires pendant le workflow.
