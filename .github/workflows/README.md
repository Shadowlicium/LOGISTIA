# Workflows GitHub Actions

Ce dossier contient les workflows du projet LOGISTIA.

## `ci-cd.yml`

Ce workflow s'execute sur `push` et `pull_request` vers `main`.

Il sert a detecter rapidement les erreurs sans toucher a l'infrastructure.

### Terraform fmt

```bash
terraform fmt -check -recursive
```

Cette commande verifie le format des fichiers Terraform. `-check` fait echouer le workflow si un fichier devrait etre reformate, sans modifier le depot.

### Terraform init sans backend

```bash
terraform init -backend=false -input=false
```

`-backend=false` evite d'utiliser un vrai state pendant la validation CI. Le but est seulement de telecharger les providers et verifier le code.

`-input=false` empeche Terraform de poser des questions interactives dans le pipeline.

### Terraform validate

```bash
terraform validate
```

Cette commande valide la configuration Terraform apres l'initialisation.

### Ansible syntax check

```bash
ANSIBLE_ROLES_PATH=roles ansible-playbook -i inventory.ini --syntax-check playbooks/site.yml
```

Le syntax-check verifie la structure du playbook sans se connecter aux machines.

`ANSIBLE_ROLES_PATH=roles` force Ansible a trouver les roles meme si `ansible.cfg` est ignore par l'environnement.

### Trivy

```bash
trivy fs --format table --exit-code 1 --severity CRITICAL,HIGH --ignore-unfixed .
```

Trivy scanne les fichiers du depot pour detecter des vulnerabilites connues. Le workflow echoue sur les severites `HIGH` et `CRITICAL`.

`--ignore-unfixed` evite d'echouer sur des vulnerabilites sans correctif disponible.

## `deploy-with-self-hosted-runner.yml`

Ce workflow est manuel avec `workflow_dispatch`.

Il tourne sur `self-hosted`, donc sur le runner interne du projet.

### Verification des secrets

Les commandes `test -n` verifient que les secrets essentiels sont presents avant de lancer Terraform ou Ansible. Cela fait echouer le workflow rapidement si une variable manque.

### Terraform wrapper desactive

```yaml
terraform_wrapper: false
```

Le wrapper Terraform de l'action HashiCorp utilise Node.js. Le runner local n'a pas forcement Node disponible. Le workflow appelle donc directement le binaire Terraform.

### State persistant

Le workflow prepare `TF_STATE_PATH` avec :

```bash
state_path="${TERRAFORM_STATE_PATH:-/srv/logistia/terraform/terraform.tfstate}"
```

Le state est conserve hors du workspace GitHub Actions. Cela evite de le perdre quand le runner nettoie son dossier de travail.

### Terraform plan puis apply

```bash
terraform plan -input=false -out=plan.tfplan
terraform apply -auto-approve plan.tfplan
```

Le plan est calcule avant l'application. `apply` utilise le fichier genere afin d'appliquer exactement ce qui a ete planifie.

`apply` ne s'execute que si l'option `terraform_action` vaut `apply`.

### Venv Ansible

```bash
python3 -m venv "$RUNNER_TEMP/ansible-venv"
```

Ansible est installe dans un environnement Python temporaire. Cela evite de modifier le systeme du runner et garantit une installation propre par execution.

### Generation des fichiers secrets Ansible

Le workflow ecrit temporairement :

- `ansible/group_vars/all.yml`
- `ansible/group_vars/mail.yml`

Ces fichiers viennent des secrets GitHub et ne sont pas versionnes.

### Attente SSH

```bash
ansible managed_containers -i inventory.ini -m wait_for_connection -a "timeout=300"
```

Cette commande attend que les conteneurs soient joignables en SSH avant de lancer le playbook complet.

Le groupe `managed_containers` exclut Proxmox pour ne configurer que les machines creees par Terraform.

### Timeout Ansible

Le step `Run Ansible playbook` a un timeout de 45 minutes. Ce choix evite qu'un blocage APT ou reseau garde le runner occupe sans fin.
