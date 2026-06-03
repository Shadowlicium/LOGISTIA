# Modules Terraform

Ce dossier regroupe les modules Terraform reutilisables.

Un module Terraform sert a transformer un bloc technique repetitif en composant lisible. Dans LOGISTIA, le module principal est `vm/`, utilise pour creer les conteneurs LXC Proxmox.

## Pourquoi utiliser des modules

Sans module, chaque conteneur devrait recopier toute la ressource Proxmox :

- configuration du systeme
- disque
- RAM
- interface reseau
- IP
- cle SSH
- options LXC

Avec un module, le fichier racine ne declare que les differences entre les machines.

## Comment lire un module

Un module Terraform contient en general :

- `variables.tf` pour les entrees attendues
- `main.tf` pour les ressources creees
- `outputs.tf` pour les valeurs exposees en sortie

Le fichier racine appelle ensuite le module avec :

```hcl
module "vm_web" {
  source = "./modules/vm"
  name   = "web-apache"
}
```

`source` indique ou se trouve le module. Les autres valeurs remplissent les variables declarees par le module.
