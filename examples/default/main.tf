terraform {
  required_version = ">= 1.9, < 2.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
    random = {
      source  = "hashicorp/random"
      version = ">= 3.0.0"
    }
  }
}

provider "azurerm" {
  features {}
}

# Get current client configuration for Key Vault access policy
data "azurerm_client_config" "current" {}

## Section to provide a random Azure region for the resource group
# This allows us to randomize the region for the resource group.
module "regions" {
  source  = "Azure/avm-utl-regions/azurerm"
  version = "~> 0.1"

  geography_filter = "United States"
}

# This allows us to randomize the region for the resource group.
resource "random_integer" "region_index" {
  max = length(module.regions.regions) - 1
  min = 0
}
## End of section to provide a random Azure region for the resource group

# This ensures we have unique CAF compliant names for our resources.
module "naming" {
  source  = "Azure/naming/azurerm"
  version = "~> 0.3"
}

# This is required for resource modules
resource "azurerm_resource_group" "this" {
  location = module.regions.regions[random_integer.region_index.result].name
  name     = module.naming.resource_group.name_unique
}

resource "azurerm_container_app_environment" "this" {
  location            = azurerm_resource_group.this.location
  name                = "my-environment"
  resource_group_name = azurerm_resource_group.this.name
}

# Service Bus namespace for event trigger example
resource "azurerm_servicebus_namespace" "this" {
  location            = azurerm_resource_group.this.location
  name                = "${module.naming.servicebus_namespace.name_unique}-event-trigger"
  resource_group_name = azurerm_resource_group.this.name
  sku                 = "Standard"
}

# Service Bus queue for event trigger example
resource "azurerm_servicebus_queue" "this" {
  name         = "my-queue"
  namespace_id = azurerm_servicebus_namespace.this.id
}

module "log_analytics_workspace" {
  source  = "Azure/avm-res-operationalinsights-workspace/azurerm"
  version = "0.4.2"

  location            = azurerm_resource_group.this.location
  name                = "la${module.naming.log_analytics_workspace.name_unique}"
  resource_group_name = azurerm_resource_group.this.name
  log_analytics_workspace_identity = {
    type = "SystemAssigned"
  }
  log_analytics_workspace_retention_in_days = 30
  log_analytics_workspace_sku               = "PerGB2018"
}

# Create a Key Vault for the secret example
resource "azurerm_key_vault" "example" {
  location                   = azurerm_resource_group.this.location
  name                       = module.naming.key_vault.name_unique
  resource_group_name        = azurerm_resource_group.this.name
  sku_name                   = "standard"
  tenant_id                  = data.azurerm_client_config.current.tenant_id
  enable_rbac_authorization  = false
  purge_protection_enabled   = false
  soft_delete_retention_days = 7
}

# Create a secret in the Key Vault
resource "azurerm_key_vault_secret" "example" {
  key_vault_id = azurerm_key_vault.example.id
  name         = "my-secret"
  value        = "secret-value-from-key-vault"
}

# This is the module call
# Do not specify location here due to the randomization above.
# Leaving location as `null` will cause the module to use the resource group location
# with a data source.

# This module creates a container app with a manual trigger.
module "manual_trigger" {
  source = "../../"

  container_app_environment_resource_id = azurerm_container_app_environment.this.id
  location                              = azurerm_resource_group.this.location
  name                                  = "${module.naming.container_app.name_unique}-job-mt"
  resource_group_name                   = azurerm_resource_group.this.name
  template = {
    container = {
      name    = "my-container"
      image   = "docker.io/ubuntu"
      command = ["echo"]
      args    = ["Hello, World!"]
      cpu     = 0.5
      memory  = "1Gi"
    }
  }
  trigger_config = {
    manual_trigger_config = {
      parallelism              = 1
      replica_completion_count = 1
    }
  }
}

# This module creates a container app with a schedule_trigger.
module "schedule_trigger" {
  source = "../../"

  container_app_environment_resource_id = azurerm_container_app_environment.this.id
  location                              = azurerm_resource_group.this.location
  name                                  = "${module.naming.container_app.name_unique}-job-st"
  resource_group_name                   = azurerm_resource_group.this.name
  template = {
    container = {
      name    = "my-container"
      image   = "docker.io/ubuntu"
      command = ["echo"]
      args    = ["Hello, World!"]
      cpu     = 0.5
      memory  = "1Gi"
      # Example of referencing a secret in environment variables
      env = [
        {
          name        = "SECRET_VALUE"
          secret_name = "example-secret"
        },
        {
          name        = "KV_SECRET_VALUE"
          secret_name = "kv-secret"
        }
      ]
    }
  }
  managed_identities = {
    system_assigned = true
  }
  # Example of using secrets
  secrets = [
    {
      name  = "example-secret"
      value = "example-secret-value"
    },
    {
      name                = "kv-secret"
      identity            = "System"
      key_vault_secret_id = azurerm_key_vault_secret.example.id
    }
  ]
  trigger_config = {
    schedule_trigger_config = {
      cron_expression          = "0 * * * *"
      parallelism              = 1
      replica_completion_count = 1
    }
  }
}

# Grant the container app job's system-assigned managed identity access to the Key Vault
resource "azurerm_key_vault_access_policy" "container_app_job" {
  key_vault_id = azurerm_key_vault.example.id
  object_id    = module.schedule_trigger.managed_identities.system_assigned.principal_id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  secret_permissions = [
    "Get"
  ]
}

# This module creates a container app with an event_trigger.
module "event_trigger" {
  source = "../../"

  container_app_environment_resource_id = azurerm_container_app_environment.this.id
  location                              = azurerm_resource_group.this.location
  name                                  = "${module.naming.container_app.name_unique}-job-et"
  resource_group_name                   = azurerm_resource_group.this.name
  template = {
    container = {
      name    = "my-container"
      image   = "docker.io/ubuntu"
      command = ["echo"]
      args    = ["Hello, World!"]
      cpu     = 0.5
      memory  = "1Gi"
    }
  }
  managed_identities = {
    system_assigned = true
  }
  # Example of using secrets
  secrets = [
    {
      name  = "servicebus-connection"
      value = azurerm_servicebus_namespace.this.default_primary_connection_string
    }
  ]
  trigger_config = {
    event_trigger_config = {
      parallelism              = 1
      replica_completion_count = 1
      scale = {
        max_executions              = 10
        min_executions              = 0
        polling_interval_in_seconds = 30
        rules = [
          {
            name             = "my-custom-rule"
            custom_rule_type = "azure-servicebus"
            metadata = {
              "queueName" = azurerm_servicebus_queue.this.name
              "namespace" = azurerm_servicebus_namespace.this.name
            }
            authentication = {
              secret_name       = "servicebus-connection"
              trigger_parameter = "connection"
            }
          }
        ]
      }
    }
  }
}


