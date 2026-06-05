# Role db_logistia

Ce role cree la base metier du portail LOGISTIA sur le conteneur PostgreSQL.

Il est separe du role `db`, qui gere la base mail, Roundcube et le schema compatible PostfixAdmin. Cette separation evite de melanger les donnees applicatives metier et les donnees de messagerie.

## Variables

Les valeurs sensibles doivent venir de `ANSIBLE_MAIL_VARS` :

```yaml
logistia_app_enabled: true
logistia_db_name: logistia
logistia_db_user: logistia_user
logistia_db_password: "replace-with-a-strong-logistia-password"
logistia_web_password_hash: "bcrypt-hash"
```

`logistia_web_password_hash` est un hash Bcrypt compatible avec `password_verify()` en PHP.

Exemple de generation :

```bash
php -r "echo password_hash('mot-de-passe', PASSWORD_BCRYPT), PHP_EOL;"
```

## Tables

Le role cree les tables :

- `entrepots`
- `clients`
- `produits`
- `stocks`
- `commandes`
- `lignes_commande`
- `utilisateurs`

Des donnees de demonstration peuvent etre inserees avec `logistia_seed_sample_data: true`.
