<!-- BEGIN_TF_DOCS -->
<!-- Code generated by terraform-docs. DO NOT EDIT. -->
# Default example

This deploys the module in its simplest form.

```hcl
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

module "log_analytics_workspace" {
  source  = "Azure/avm-res-operationalinsights-workspace/azurerm"
  version = "0.4.2"

  location            = azurerm_resource_group.this.location
  name                = "la${module.naming.log_analytics_workspace.name_unique}"
  resource_group_name = azurerm_resource_group.this.name
  enable_telemetry    = var.enable_telemetry
  log_analytics_workspace_identity = {
    type = "SystemAssigned"
  }
  log_analytics_workspace_retention_in_days = 30
  log_analytics_workspace_sku               = "PerGB2018"
}

resource "azurerm_container_app_environment" "this" {
  location                   = azurerm_resource_group.this.location
  name                       = "my-environment"
  resource_group_name        = azurerm_resource_group.this.name
  log_analytics_workspace_id = module.log_analytics_workspace.resource_id
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
  enable_telemetry = var.enable_telemetry
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
    }
  }
  enable_telemetry = var.enable_telemetry
  managed_identities = {
    system_assigned = true
  }
  trigger_config = {
    schedule_trigger_config = {
      cron_expression          = "0 * * * *"
      parallelism              = 1
      replica_completion_count = 1
    }
  }
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
  enable_telemetry = var.enable_telemetry
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
```

<!-- markdownlint-disable MD033 -->
## Requirements

The following requirements are needed by this module:

- <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) (>= 1.9, < 2.0)

- <a name="requirement_azurerm"></a> [azurerm](#requirement\_azurerm) (~> 4.0)

- <a name="requirement_random"></a> [random](#requirement\_random) (>= 3.0.0)

## Resources

The following resources are used by this module:

- [azurerm_container_app_environment.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/container_app_environment) (resource)
- [azurerm_resource_group.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/resource_group) (resource)
- [azurerm_servicebus_namespace.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/servicebus_namespace) (resource)
- [azurerm_servicebus_queue.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/servicebus_queue) (resource)
- [random_integer.region_index](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/integer) (resource)

<!-- markdownlint-disable MD013 -->
## Required Inputs

No required inputs.

## Optional Inputs

The following input variables are optional (have default values):

### <a name="input_enable_telemetry"></a> [enable\_telemetry](#input\_enable\_telemetry)

Description: This variable controls whether or not telemetry is enabled for the module.  
For more information see <https://aka.ms/avm/telemetryinfo>.  
If it is set to false, then no telemetry will be collected.

Type: `bool`

Default: `true`

## Outputs

No outputs.

## Modules

The following Modules are called:

### <a name="module_event_trigger"></a> [event\_trigger](#module\_event\_trigger)

Source: ../../

Version:

### <a name="module_log_analytics_workspace"></a> [log\_analytics\_workspace](#module\_log\_analytics\_workspace)

Source: Azure/avm-res-operationalinsights-workspace/azurerm

Version: 0.4.2

### <a name="module_manual_trigger"></a> [manual\_trigger](#module\_manual\_trigger)

Source: ../../

Version:

### <a name="module_naming"></a> [naming](#module\_naming)

Source: Azure/naming/azurerm

Version: ~> 0.3

### <a name="module_regions"></a> [regions](#module\_regions)

Source: Azure/avm-utl-regions/azurerm

Version: ~> 0.1

### <a name="module_schedule_trigger"></a> [schedule\_trigger](#module\_schedule\_trigger)

Source: ../../

Version:

<!-- markdownlint-disable-next-line MD041 -->
## Data Collection

The software may collect information about you and your use of the software and send it to Microsoft. Microsoft may use this information to provide services and improve our products and services. You may turn off the telemetry as described in the repository. There are also some features in the software that may enable you and Microsoft to collect data from users of your applications. If you use these features, you must comply with applicable law, including providing appropriate notices to users of your applications together with a copy of Microsoft’s privacy statement. Our privacy statement is located at <https://go.microsoft.com/fwlink/?LinkID=824704>. You can learn more about data collection and use in the help documentation and our privacy statement. Your use of the software operates as your consent to these practices.
<!-- END_TF_DOCS -->