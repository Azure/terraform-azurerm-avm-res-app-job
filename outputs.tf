output "container_app_job_name" {
  description = "The name of the Container App Job."
  value       = azurerm_container_app_job.this.name
}

output "managed_identities" {
  description = "The managed identities for the Container App Job."
  value = {
    system_assigned = var.managed_identities.system_assigned ? {
      principal_id = azurerm_container_app_job.this.identity[0].principal_id
      tenant_id    = azurerm_container_app_job.this.identity[0].tenant_id
    } : null
    user_assigned = length(var.managed_identities.user_assigned_resource_ids) > 0 ? {
      identity_ids = tolist(azurerm_container_app_job.this.identity[0].identity_ids)
    } : null
  }
}

output "resource_id" {
  description = "The ID of the Container App Job."
  value       = azurerm_container_app_job.this.id
}
