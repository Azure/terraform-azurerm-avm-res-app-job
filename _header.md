# terraform-azurerm-avm-res-app-job

This Terraform module creates and manages Azure Container App Jobs with support for secrets, environment variables, and various trigger configurations.

## Features

- **Container App Job Creation**: Deploy container applications as jobs in Azure Container Apps
- **Secret Management**: Support for both plain text secrets and Azure Key Vault references
- **Flexible Triggers**: Manual, scheduled, and event-based trigger configurations
- **Environment Variables**: Configure environment variables with support for secret references
- **Managed Identity**: Built-in support for system-assigned and user-assigned managed identities
- **Init Containers**: Support for initialization containers
- **Volume Mounting**: Storage volume mounting capabilities

## Secret Support

This module supports two types of secrets:

1. **Plain Text Secrets**: Store secret values directly in the configuration
2. **Azure Key Vault Secrets**: Reference secrets stored in Azure Key Vault with proper identity configuration

For production workloads, Azure Key Vault secrets are recommended for enhanced security.
