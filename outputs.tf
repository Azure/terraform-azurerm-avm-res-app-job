output "container_app_job_id" {
  description = "The ID of the Container App Job."
  value       = azurerm_container_app_job.this.id
}

output "container_app_job_name" {
  description = "The name of the Container App Job."
  value       = azurerm_container_app_job.this.name
}
