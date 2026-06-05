# Role mail_log_forwarder

Ce role configure les serveurs mail pour envoyer leurs logs mail vers `ollama-ia`.

## Fonctionnement

Les machines `mail-relay` et `mail-data` envoient les logs `mail.*` avec rsyslog vers :

```text
{{ mail_log_ai_host }}:{{ mail_log_ai_port }}
```

Le role `ollama` configure le serveur IA pour recevoir ces logs dans `/var/log/ollama/remote-mail.log`.

## Variables

| Variable | Valeur par defaut | Role |
|---|---|---|
| `mail_log_forwarding_enabled` | `true` | active l'envoi des logs mail |
| `mail_log_ai_host` | `10.10.40.11` | adresse du serveur IA |
| `mail_log_ai_port` | `514` | port TCP rsyslog |
