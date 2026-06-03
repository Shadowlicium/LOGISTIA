# Terraform LOGISTIA

Ce dossier cree les conteneurs LXC du projet sur Proxmox.

Terraform ne configure pas les applications. Il prepare les machines avec leurs ressources, leurs adresses IP et une cle SSH publique. Les services sont ensuite installes par Ansible.

## Fichiers principaux

| Fichier | Role |
|---|---|
| `main.tf` | declare le provider Proxmox et les conteneurs a creer |
| `variables.tf` | declare les variables configurables |
| `outputs.tf` | expose les informations utiles apres creation |
| `terraform.tfvars.example` | modele de variables locales |
| `modules/vm/` | module reutilisable pour creer un conteneur LXC |

## Pourquoi utiliser un module

Les conteneurs ont beaucoup de parametres communs :

- noeud Proxmox
- template LXC
- stockage
- disque
- RAM
- bridge reseau
- IP et passerelle
- cle SSH

Le module `modules/vm` evite de recopier toute la ressource Proxmox pour chaque machine. Le fichier `main.tf` ne garde que les differences importantes : nom, VMID, IP, ressources et zone reseau.

## Variables locales

Le fichier `terraform.tfvars` est cree a partir de l'exemple :

```bash
cp terraform.tfvars.example terraform.tfvars
```

Cette commande copie un modele versionne vers un fichier local ignore par Git. Le fichier local contient les vraies valeurs de l'environnement, par exemple l'URL Proxmox et les identifiants.

Exemple :

```hcl
proxmox_url      = "https://192.168.160.100:8006/api2/json"
proxmox_user     = "terraform@pve"
proxmox_password = "change-me"
ssh_public_key   = "ssh-ed25519 AAAA..."
```

## Commandes Terraform

### `terraform init`

```bash
terraform init
```

Cette commande initialise le dossier Terraform. Elle telecharge le provider `bpg/proxmox`, prepare le dossier `.terraform/` et configure le backend du state.

Elle est necessaire avant `validate`, `plan` ou `apply`.

### `terraform validate`

```bash
terraform validate
```

Cette commande verifie que les fichiers `.tf` sont syntaxiquement corrects et que les variables/modules sont coherents.

Elle ne contacte pas forcement Proxmox et ne cree aucune ressource.

### `terraform fmt`

```bash
terraform fmt -recursive
```

Cette commande reformate les fichiers Terraform avec le style officiel. Le pipeline utilise `terraform fmt -check -recursive` pour verifier que le format est deja correct.

### `terraform plan`

```bash
terraform plan -out=plan.tfplan
```

Cette commande compare l'etat actuel connu par Terraform avec le code du depot. Elle affiche ce qui sera cree, modifie ou detruit.

Le fichier `plan.tfplan` fige le plan. Cela permet d'appliquer exactement ce qui a ete relu.

### `terraform apply`

```bash
terraform apply plan.tfplan
```

Cette commande applique les changements prevus par le plan. Dans ce projet, elle cree ou modifie des conteneurs LXC sur Proxmox.

## Backend local

Le projet declare un backend local. En execution manuelle, Terraform utilise le state local du dossier. Dans le workflow GitHub Actions, le chemin est force vers un emplacement persistant du runner :

```text
/srv/logistia/terraform/terraform.tfstate
```

Ce choix evite de versionner le state tout en permettant au runner de retrouver l'infrastructure deja creee apres un redemarrage.

## Reseau

Chaque conteneur recoit une IP statique et une passerelle. Le routage entre zones est assure par l'equipement reseau ou le routeur/firewall de l'infrastructure.

Les variables `gateway_*` permettent de garder le code Terraform lisible, meme si l'adresse de passerelle change par zone.

## Secrets

`proxmox_password` est marque `sensitive`. Cette protection limite son affichage dans les sorties Terraform, mais elle ne remplace pas les bonnes pratiques :

- pas de `terraform.tfvars` dans Git
- pas de state Terraform dans Git
- secrets fournis par GitHub Actions pour le pipeline
