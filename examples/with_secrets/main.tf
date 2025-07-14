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


## Section to provide a random Azure region for the resource group
# This allows us to randomize the region for the resource group.
module "regions" {
  source  = "Azure/avm-utl-regions/azurerm"
  version = "~> 0.1"
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

# This module creates a container app job with secrets
module "container_app_job_with_secrets" {
  source = "../../"

  container_app_environment_resource_id = azurerm_container_app_environment.this.id
  location                              = azurerm_resource_group.this.location
  name                                  = "${module.naming.container_app.name_unique}-job-secrets"
  resource_group_name                   = azurerm_resource_group.this.name
  template = {
    container = {
      name    = "my-container"
      image   = "docker.io/ubuntu"
      command = ["echo"]
      args    = ["Hello, World!"]
      cpu     = 0.5
      memory  = "1Gi"
      # Environment variables can reference the secrets
      env = [
        {
          name        = "SECRET_VALUE"
          secret_name = "my-secret"
        },
        {
          name        = "DB_PASSWORD"
          secret_name = "database-password"
        },
        {
          name  = "PLAIN_VALUE"
          value = "not-a-secret"
        }
      ]
    }
  }
  enable_telemetry = var.enable_telemetry
  # Define secrets for the container app job
  secrets = [
    {
      name  = "my-secret"
      value = "secret-value"
    },
    {
      name  = "database-password"
      value = "supersecretpassword"
    }
  ]
  trigger_config = {
    manual_trigger_config = {
      parallelism              = 1
      replica_completion_count = 1
    }
  }
}