output "web_vmid" {
  value       = module.vm_web.vmid
  description = "VMID du serveur web"
}

output "db_vmid" {
  value       = module.vm_db.vmid
  description = "VMID de la base de données"
}

output "grafana_vmid" {
  value       = module.vm_grafana.vmid
  description = "VMID de Grafana"
}

output "mail_relay_vmid" {
  value       = module.vm_postfix.vmid
  description = "VMID du relais mail en DMZ"
}

output "mail_backend_vmid" {
  value       = module.vm_mail_backend.vmid
  description = "VMID du serveur mail interne"
}

output "ollama_vmid" {
  value       = module.vm_ollama.vmid
  description = "VMID d'Ollama IA"
}

output "backup_vmid" {
  value       = try(module.vm_backup[0].vmid, null)
  description = "VMID du serveur de backup"
}
