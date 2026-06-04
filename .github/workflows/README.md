# Workflows GitHub Actions

Ce dossier contient les workflows du projet LOGISTIA.

Les workflows sont separes en deux usages :

- `ci-cd.yml` verifie le depot sans modifier l'infrastructure.
- `deploy-with-self-hosted-runner.yml` cree ou met a jour les conteneurs et lance Ansible depuis le runner interne.

## Vue d'ensemble des jobs

| Workflow | Job | Declenchement | Runner | Effet sur l'infrastructure |
|---|---|---|---|---|
| `ci-cd.yml` | `validate` | `push` et `pull_request` vers `main` | `ubuntu-latest` | aucun |
| `ci-cd.yml` | `security-scan` | apres `validate` | `ubuntu-latest` | aucun |
| `deploy-with-self-hosted-runner.yml` | `deploy` | manuel avec `workflow_dispatch` | `self-hosted` | Terraform et Ansible selon les options |

## Workflow `ci-cd.yml`

Ce workflow sert a detecter rapidement les erreurs avant un deploiement. Il ne contacte pas Proxmox et ne se connecte pas aux conteneurs.

### Job `validate`

Le job `validate` controle la qualite technique minimale du code Terraform et Ansible.

#### Checkout

```yaml
uses: actions/checkout@v4
```

Cette action recupere le contenu du depot dans le workspace du runner GitHub. Les commandes suivantes travaillent donc sur la meme version du code que celle envoyee sur GitHub.

#### Setup Terraform

```yaml
uses: hashicorp/setup-terraform@v3
```

Cette action installe Terraform sur le runner temporaire `ubuntu-latest`. Elle permet d'utiliser une version propre de Terraform sans dependre d'une installation preexistante.

#### Terraform fmt

```bash
terraform fmt -check -recursive
```

Cette commande verifie le format des fichiers Terraform. `-check` fait echouer le workflow si un fichier devrait etre reformate, sans modifier le depot. `-recursive` controle aussi les modules.

#### Terraform init sans backend

```bash
terraform init -backend=false -input=false
```

`-backend=false` evite d'utiliser un vrai state pendant la validation CI. Le but est seulement de telecharger les providers et de verifier le code.

`-input=false` empeche Terraform de poser des questions interactives dans le pipeline.

#### Terraform validate

```bash
terraform validate
```

Cette commande valide la configuration Terraform apres l'initialisation. Elle verifie la syntaxe, les variables, les providers et les modules, sans creer de ressource Proxmox.

#### Install Ansible

Le workflow cree un environnement Python et installe Ansible ainsi que les collections declarees dans `ansible/requirements.yml`.

Cela permet de verifier Ansible dans la CI GitHub meme si le runner temporaire ne possede pas Ansible au depart.

#### Ansible syntax check

```bash
ANSIBLE_ROLES_PATH=roles ansible-playbook -i inventory.ini --syntax-check playbooks/site.yml
```

Le syntax-check verifie la structure du playbook sans se connecter aux machines.

`ANSIBLE_ROLES_PATH=roles` force Ansible a trouver les roles meme si `ansible.cfg` est ignore par l'environnement.

### Job `security-scan`

Le job `security-scan` depend de `validate`. Il ne demarre que si le job de validation est reussi.

#### Install Trivy

Le workflow installe Trivy depuis le depot officiel APT d'Aqua Security. Cette installation est faite dans le job pour garder le runner temporaire interchangeable.

#### Trivy filesystem scan

```bash
trivy fs --format table --exit-code 1 --severity CRITICAL,HIGH --ignore-unfixed .
```

Trivy scanne les fichiers du depot pour detecter des vulnerabilites connues.

`--exit-code 1` fait echouer le job si une vulnerabilite correspondant aux criteres est trouvee.

`--severity CRITICAL,HIGH` limite le blocage aux vulnerabilites hautes et critiques.

`--ignore-unfixed` evite d'echouer sur des vulnerabilites sans correctif disponible.

## Workflow `deploy-with-self-hosted-runner.yml`

Ce workflow est manuel avec `workflow_dispatch`.

Il tourne sur `self-hosted`, donc sur le runner interne du projet. Ce runner doit pouvoir joindre Proxmox, le state Terraform persistant et les VLANs prives utilises par Ansible.

### Job `deploy`

Le job `deploy` est le seul job de ce workflow. Il peut faire un simple `terraform plan`, ou appliquer Terraform puis lancer Ansible.

Les options disponibles au lancement sont :

| Option | Effet |
|---|---|
| `terraform_action = plan` | calcule uniquement les changements Terraform |
| `terraform_action = apply` | applique les changements Terraform |
| `run_ansible = true` | lance Ansible apres Terraform |
| `run_ansible = false` | limite l'execution a Terraform |
| `deploy_backup = true` | cree et configure le serveur backup |
| `deploy_backup = false` | exclut le serveur backup |

#### Concurrence

```yaml
concurrency:
  group: logistia-deploy
  cancel-in-progress: false
```

Cette configuration empeche deux deploiements LOGISTIA de s'executer en meme temps. `cancel-in-progress: false` evite d'interrompre un deploiement deja lance.

#### Checkout

Le checkout recupere le depot sur le runner interne.

`persist-credentials: false` evite de garder le token GitHub dans la configuration Git locale apres le checkout.

#### Verification des secrets Terraform

Les commandes `test -n` verifient que les secrets Terraform essentiels sont presents avant de lancer `terraform init` ou `terraform plan`.

Les variables verifiees sont :

- `TF_VAR_proxmox_url`
- `TF_VAR_proxmox_user`
- `TF_VAR_proxmox_password`
- `TF_VAR_ssh_public_key`

Les variables `TF_VAR_*` sont lues automatiquement par Terraform.

`TF_VAR_deploy_backup` vient de l'option manuelle `deploy_backup`. Elle controle la creation du conteneur backup.

#### Protection du state backup

Si `deploy_backup = false`, le workflow verifie le state Terraform avant le plan.

Si un backup est deja present dans le state, le workflow echoue volontairement. Cela evite de demander a Terraform de supprimer un conteneur qui contient potentiellement les sauvegardes.

#### Verification des secrets Ansible

Quand `terraform_action = apply` et `run_ansible = true`, le workflow verifie aussi :

- `ANSIBLE_MAIL_VARS`
- `ANSIBLE_ADMIN_SSH_PUBLIC_KEY`
- `ANSIBLE_SSH_PRIVATE_KEY`

Cette verification evite de creer les machines puis de bloquer immediatement sur un secret Ansible manquant.

#### Verification des prerequis runner

Le workflow controle la presence de commandes locales comme `python3`, `ssh-keygen` et `venv`.

Le runner self-hosted est une machine longue duree, donc cette verification donne une erreur lisible si un paquet systeme manque.

#### Terraform wrapper desactive

```yaml
terraform_wrapper: false
```

Le wrapper Terraform de l'action HashiCorp utilise Node.js. Le runner local n'a pas forcement Node disponible. Le workflow appelle donc directement le binaire Terraform.

#### State persistant

Le workflow prepare `TF_STATE_PATH` avec :

```bash
state_path="${TERRAFORM_STATE_PATH:-/srv/logistia/terraform/terraform.tfstate}"
```

Le state est conserve hors du workspace GitHub Actions. Cela evite de le perdre quand le runner nettoie son dossier de travail.

Le dossier parent du state doit exister et etre accessible en ecriture par l'utilisateur du runner.

#### Terraform init

```bash
terraform init -input=false -backend-config="path=$TF_STATE_PATH"
```

Cette commande initialise Terraform avec le backend local pointe vers le chemin persistant du runner. Le state garde le lien entre le code et les ressources Proxmox deja creees.

#### Terraform plan

```bash
terraform plan -input=false -out=plan.tfplan
```

Le plan compare le code du depot, le state Terraform et l'etat Proxmox. Le fichier `plan.tfplan` fige le resultat pour l'etape suivante.

#### Terraform apply

```bash
terraform apply -auto-approve plan.tfplan
```

`apply` applique exactement le plan genere precedemment.

Cette etape ne s'execute que si l'option `terraform_action` vaut `apply`.

#### Installation Ansible dans un venv

```bash
python3 -m venv "$RUNNER_TEMP/ansible-venv"
```

Ansible est installe dans un environnement Python temporaire. Cela evite de modifier le systeme du runner et garantit une installation propre par execution.

#### Configuration de la cle SSH Ansible

Le secret `ANSIBLE_SSH_PRIVATE_KEY` est ecrit dans `~/.ssh/id_ed25519` avec des permissions strictes.

Cette cle doit correspondre a la cle publique injectee dans les conteneurs par Terraform.

#### Generation des fichiers secrets Ansible

Le workflow ecrit temporairement :

- `ansible/group_vars/all.yml`
- `ansible/group_vars/mail.yml`

Ces fichiers viennent des secrets GitHub et ne sont pas versionnes. Ils sont recrees a chaque execution du workflow.

Le fichier `all.yml` contient aussi `backup_enabled`. Cette variable permet a Ansible de ne pas appliquer les roles backup quand `deploy_backup = false`.

#### Attente SSH

```bash
ansible managed_containers -i inventory.ini -m wait_for_connection -a "timeout=300"
```

Cette commande attend que les conteneurs soient joignables en SSH avant de lancer le playbook complet.

Le groupe `managed_containers` exclut Proxmox pour ne configurer que les machines creees par Terraform.

Quand `deploy_backup = false`, le workflow attend `managed_containers:!backups` pour ne pas bloquer sur un serveur backup non cree.

#### Execution du playbook Ansible

```bash
ANSIBLE_ROLES_PATH=roles ansible-playbook -i inventory.ini playbooks/site.yml
```

Le playbook installe les paquets, cree les utilisateurs d'administration, configure les services et applique les roles applicatifs.

Quand `deploy_backup = false`, le playbook est lance avec `--limit "all:!backups"` pour exclure le serveur backup.

Le step a un timeout de 45 minutes. Ce choix evite qu'un blocage APT ou reseau garde le runner occupe sans fin.

## Procedure de rollback

Il n'y a pas de rollback automatique dans le pipeline. Terraform et Ansible sont idempotents, donc la strategie de reprise consiste a conserver le state, corriger la cause de l'echec, puis relancer le workflow.

### Regles generales

- Ne pas supprimer le fichier `terraform.tfstate`.
- Ne pas lancer `terraform destroy` pour corriger un echec partiel.
- Lire le premier step en erreur dans les logs GitHub Actions.
- Verifier l'etat reel dans Proxmox avant toute correction manuelle.
- Lancer un `terraform plan` apres correction pour voir l'ecart restant.

### Echec avant `Terraform apply`

Cas typiques : secret manquant, format Terraform incorrect, erreur de validation, state inaccessible.

Aucune ressource Proxmox n'est modifiee. La correction se fait dans le depot, dans les secrets GitHub ou sur le runner, puis le workflow peut etre relance.

### Echec pendant `Terraform apply`

Terraform peut avoir cree une partie des ressources avant l'erreur.

Le state persistant indique normalement ce qui a ete cree. La procedure est :

1. conserver le state existant ;
2. corriger la cause de l'erreur ;
3. relancer le workflow avec `terraform_action = plan` pour verifier l'ecart ;
4. relancer avec `terraform_action = apply` si le plan est coherent.

Si une ressource existe dans Proxmox mais pas dans le state, elle doit etre soit importee avec `terraform import`, soit supprimee manuellement apres verification. La suppression manuelle reste un dernier recours.

### Echec pendant Ansible

Dans ce cas, les conteneurs existent deja. L'echec concerne souvent SSH, APT, une variable manquante ou une configuration service.

La correction se fait dans les roles Ansible, les secrets ou le reseau. Le workflow peut ensuite etre relance avec `terraform_action = apply` et `run_ansible = true`. Si le state est correct, Terraform ne devrait rien changer et Ansible reprendra les roles de maniere idempotente.

Pour tester uniquement depuis le runner ou un poste d'administration :

```bash
cd ansible
ANSIBLE_ROLES_PATH=roles ansible-playbook -i inventory.ini playbooks/site.yml
```

### Retour a une version precedente du depot

Le retour arriere Git recommande est `git revert`, car il garde un historique lisible et fonctionne bien avec GitHub.

Exemple :

```bash
git revert <commit>
git push
```

Apres le revert, le workflow de deploiement applique la configuration redevenue courante.

### Rollback d'une configuration applicative

Ansible ecrit les configurations des services depuis les roles versionnes dans Git. Pour revenir sur une configuration :

1. revenir au contenu voulu dans le role Ansible ;
2. valider avec le workflow `ci-cd.yml` ;
3. relancer le deploiement Ansible.

Les donnees applicatives, comme les bases PostgreSQL ou les boites mail, ne sont pas restaurees par Git. Leur rollback depend des sauvegardes du serveur `backup`.
