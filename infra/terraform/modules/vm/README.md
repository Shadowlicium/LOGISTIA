# Module Terraform vm

Ce module cree un conteneur LXC Proxmox avec le provider `bpg/proxmox`.

Il est utilise pour toutes les machines applicatives du projet LOGISTIA.

## Entrees principales

| Variable | Role |
|---|---|
| `name` | nom du conteneur et hostname |
| `target_node` | noeud Proxmox ou creer le conteneur |
| `vmid` | identifiant Proxmox unique |
| `ostemplate` | template LXC Ubuntu |
| `cores` | nombre de CPU |
| `memory` | RAM dediee en Mo |
| `rootfs_size` | taille disque |
| `storage` | stockage Proxmox |
| `bridge` | bridge Proxmox attache a l'interface |
| `vlan` | identifiant VLAN applique a l'interface |
| `ip` | IP statique avec masque CIDR |
| `gateway` | passerelle par defaut |
| `ssh_keys` | cles publiques injectees dans root |

## Pourquoi un conteneur LXC

Les conteneurs LXC consomment moins de ressources que des VM completes. Pour ce projet, ils conviennent aux services Linux classiques : Apache, Postfix, Dovecot, PostgreSQL, Grafana, Ollama et backup.

Le choix LXC permet de faire tourner plusieurs services isoles sur un Proxmox limite en RAM.

## Comment la ressource fonctionne

La ressource `proxmox_virtual_environment_container` cree le conteneur avec :

- une image systeme Ubuntu
- une configuration cloud-init equivalente pour hostname, IP et cle SSH
- un disque dans le stockage Proxmox
- une interface reseau
- des options LXC comme `nesting`

La cle SSH publique est injectee dans `initialization.user_account.keys`. Cela permet a Ansible de se connecter sans mot de passe.

## Reseau

Le bloc `network_interface` attache le conteneur a un bridge Proxmox :

```hcl
network_interface {
  name    = "eth0"
  bridge  = var.bridge
  vlan_id = var.vlan
}
```

`bridge` indique le reseau Proxmox utilise. `vlan_id` applique un tag VLAN lorsque le bridge est VLAN-aware.

Si l'infrastructure utilise un bridge dedie par zone, la variable `bridge` peut pointer vers ce bridge. Si le tag VLAN n'est plus necessaire, le module peut etre adapte pour rendre `vlan_id` optionnel.

## Sorties

Le module expose les informations necessaires au reste de Terraform, par exemple le nom ou l'IP du conteneur. Ces sorties servent a documenter ce qui a ete cree ou a alimenter d'autres modules si le projet evolue.
