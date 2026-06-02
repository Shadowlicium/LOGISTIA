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

output "postfix_vmid" {
  value       = module.vm_postfix.vmid
  description = "VMID du serveur mail (Postfix)"
}

output "ollama_vmid" {
  value       = module.vm_ollama.vmid
  description = "VMID d'Ollama IA"
}

output "runner_vmid" {
  value       = module.vm_runner.vmid
  description = "VMID du GitHub Runner"
}

output "backup_vmid" {
  value       = module.vm_backup.vmid
  description = "VMID du serveur de backup"
}
