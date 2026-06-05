output "web_vmid" {
  value       = try(module.vm_web[0].vmid, null)
  description = "VMID du serveur web"
}

output "db_vmid" {
  value       = try(module.vm_db[0].vmid, null)
  description = "VMID de la base de données"
}

output "grafana_vmid" {
  value       = try(module.vm_grafana[0].vmid, null)
  description = "VMID de Grafana"
}

output "mail_relay_vmid" {
  value       = try(module.vm_postfix[0].vmid, null)
  description = "VMID du relais mail en DMZ"
}

output "mail_backend_vmid" {
  value       = try(module.vm_mail_backend[0].vmid, null)
  description = "VMID du serveur mail interne"
}

output "ollama_vmid" {
  value       = try(module.vm_ollama[0].vmid, null)
  description = "VMID d'Ollama IA"
}

output "backup_vmid" {
  value       = try(module.vm_backup[0].vmid, null)
  description = "VMID du serveur de backup"
}
