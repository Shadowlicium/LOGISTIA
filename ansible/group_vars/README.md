# Variables Ansible

Ce dossier contient les variables partagees par les groupes Ansible.

Les fichiers `.example` sont versionnes. Les vrais fichiers `.yml` contenant les secrets sont ignores par Git.

## Fichiers

| Fichier | Role |
|---|---|
| `all.yml.example` | modele pour les variables communes |
| `mail.yml.example` | modele pour les variables mail et PostgreSQL |

## Pourquoi des exemples

Les exemples documentent les variables attendues sans exposer de secrets. Un lecteur peut comprendre la structure necessaire, puis creer son fichier local.

```bash
cp ansible/group_vars/all.yml.example ansible/group_vars/all.yml
cp ansible/group_vars/mail.yml.example ansible/group_vars/mail.yml
```

## Pourquoi chiffrer `mail.yml`

`mail.yml` contient :

- le mot de passe PostgreSQL du compte mail
- les mots de passe des utilisateurs mail
- les alias mail

En local, le fichier peut etre chiffre avec Ansible Vault :

```bash
ansible-vault encrypt ansible/group_vars/mail.yml
```

Le chiffrement evite de laisser les secrets lisibles sur disque.

## GitHub Actions

Dans le pipeline, les fichiers `all.yml` et `mail.yml` ne viennent pas du depot. Ils sont generes temporairement depuis les secrets :

- `SSH_PUBLIC_KEY`
- `ANSIBLE_MAIL_VARS`

Cela permet d'utiliser le meme playbook en local et en CI/CD sans versionner les secrets.

## Format des comptes mail

Les comptes mail virtuels utilisent le format suivant :

```yaml
mail_users:
  - email: user@mail.local
    password: "replace-with-a-strong-password"
```

Ansible insere ces utilisateurs dans PostgreSQL et hache les mots de passe en `SHA512-CRYPT`.
