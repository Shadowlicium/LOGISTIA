# GitHub Runner

Le conteneur `gh-runner` est le runner GitHub Actions interne au réseau Proxmox.

Ce rôle installe seulement les dépendances nécessaires et prépare le dossier `/opt/github-runner`. L'installation du runner lui-même doit suivre les commandes officielles affichées par GitHub.

## Installation

1. Créer le conteneur avec Terraform.
2. Appliquer Ansible pour installer les prérequis du rôle `runner`.
3. Dans GitHub, aller dans `Settings` -> `Actions` -> `Runners` -> `New self-hosted runner`.
4. Choisir Linux x64.
5. Se connecter à `gh-runner`.
6. Copier/coller les commandes données par GitHub.

## Vérification

```bash
systemctl status actions.runner.*
journalctl -u actions.runner.* -f
```

Les workflows de déploiement utilisent `runs-on: self-hosted`.
