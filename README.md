<!-- BEGIN_TF_DOCS -->
# terraform-azurerm-avm-template

This is a template repo for Terraform Azure Verified Modules.

Things to do:

1. Set up a GitHub repo environment called `test`.
1. Configure environment protection rule to ensure that approval is required before deploying to this environment.
1. Create a user-assigned managed identity in your test subscription.
1. Create a role assignment for the managed identity on your test subscription, use the minimum required role.
1. Configure federated identity credentials on the user assigned managed identity. Use the GitHub environment.
1. Search and update TODOs within the code and remove the TODO comments once complete.

<!-- markdownlint-disable MD033 -->
## Requirements

The following requirements are needed by this module:

- <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) (>= 1.9, < 2.0)

- <a name="requirement_azurerm"></a> [azurerm](#requirement\_azurerm) (~> 4.0)

- <a name="requirement_modtm"></a> [modtm](#requirement\_modtm) (~> 0.3)

- <a name="requirement_random"></a> [random](#requirement\_random) (~> 3.5)

## Resources

The following resources are used by this module:

- [azurerm_container_app_job.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/container_app_job) (resource)
- [modtm_telemetry.telemetry](https://registry.terraform.io/providers/azure/modtm/latest/docs/resources/telemetry) (resource)
- [random_uuid.telemetry](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/uuid) (resource)
- [azurerm_client_config.telemetry](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/client_config) (data source)
- [modtm_module_source.telemetry](https://registry.terraform.io/providers/azure/modtm/latest/docs/data-sources/module_source) (data source)

<!-- markdownlint-disable MD013 -->
## Required Inputs

The following input variables are required:

### <a name="input_container_app_environment_resource_id"></a> [container\_app\_environment\_resource\_id](#input\_container\_app\_environment\_resource\_id)

Description: The ID of the Container App Environment to host this Container App.

Type: `string`

### <a name="input_location"></a> [location](#input\_location)

Description: The Azure region where this and supporting resources should be deployed.

Type: `string`

### <a name="input_name"></a> [name](#input\_name)

Description: The name for this Container App.

Type: `string`

### <a name="input_resource_group_name"></a> [resource\_group\_name](#input\_resource\_group\_name)

Description: (Required) The name of the resource group in which the Container App Environment is to be created. Changing this forces a new resource to be created.

Type: `string`

### <a name="input_template"></a> [template](#input\_template)

Description: The template block describes the configuration for the Container App Job.  
It defines the main container, optional init containers, resource requirements,  
environment variables, probes (liveness, readiness, startup), and volume mounts.  
Use this variable to specify the container image, CPU/memory, commands, arguments,  
environment variables, and any additional configuration needed for the job's execution environment.

Type:

```hcl
object({
    max_replicas = optional(number)
    min_replicas = optional(number)
    container = object({
      name    = string
      image   = string
      cpu     = number
      memory  = string
      command = optional(list(string))
      args    = optional(list(string))
      env = optional(list(object({
        name        = string
        secret_name = optional(string)
        value       = optional(string)
      })))
      liveness_probe = optional(list(object({
        port                    = number
        transport               = string
        failure_count_threshold = number
        period                  = number
        header = optional(list(object({
          name  = string
          value = string
        })))
        host             = optional(string)
        initial_delay    = optional(number)
        interval_seconds = optional(number)
        path             = optional(string)
        timeout          = optional(number)
      })))
      readiness_probe = optional(list(object({
        port                    = number
        transport               = string
        failure_count_threshold = number
        header = optional(list(object({
          name  = string
          value = string
        })))
        host                    = optional(string)
        interval_seconds        = optional(number)
        path                    = optional(string)
        success_count_threshold = optional(number)
        timeout                 = optional(number)
      })))
      startup_probe = optional(list(object({
        port                    = number
        transport               = string
        failure_count_threshold = number
        header = optional(list(object({
          name  = string
          value = string
        })))
        host             = optional(string)
        interval_seconds = optional(number)
        path             = optional(string)
        timeout          = optional(number)
      })))
      volume_mounts = optional(list(object({
        name = string
        path = string
      })))
    })
    init_container = optional(list(object({
      name    = string
      image   = string
      cpu     = number
      memory  = string
      command = list(string)
      args    = list(string)
      env = optional(list(object({
        name        = string
        secret_name = optional(string)
        value       = optional(string)
      })))
    })))
    volume = optional(list(object({
      name         = optional(string)
      storage_type = optional(string)
      storage_name = optional(string)
    })))
  })
```

## Optional Inputs

The following input variables are optional (have default values):

### <a name="input_enable_telemetry"></a> [enable\_telemetry](#input\_enable\_telemetry)

Description: This variable controls whether or not telemetry is enabled for the module.  
For more information see <https://aka.ms/avm/telemetryinfo>.  
If it is set to false, then no telemetry will be collected.

Type: `bool`

Default: `true`

### <a name="input_managed_identities"></a> [managed\_identities](#input\_managed\_identities)

Description:   Controls the Managed Identity configuration on this resource. The following properties can be specified:

  - `system_assigned` - (Optional) Specifies if the System Assigned Managed Identity should be enabled.
  - `user_assigned_resource_ids` - (Optional) Specifies a list of User Assigned Managed Identity resource IDs to be assigned to this resource.

Type:

```hcl
object({
    system_assigned            = optional(bool, false)
    user_assigned_resource_ids = optional(set(string), [])
  })
```

Default: `{}`

### <a name="input_replica_timeout_in_seconds"></a> [replica\_timeout\_in\_seconds](#input\_replica\_timeout\_in\_seconds)

Description: The timeout in seconds for the job to complete.

Type: `number`

Default: `300`

### <a name="input_tags"></a> [tags](#input\_tags)

Description: (Optional) A mapping of tags to assign to the Container App Job.

Type: `map(string)`

Default: `null`

### <a name="input_trigger_config"></a> [trigger\_config](#input\_trigger\_config)

Description: Configuration for the trigger. Only one of manual\_trigger\_config, event\_trigger\_config, or schedule\_trigger\_config can be specified.

Type:

```hcl
object({
    manual_trigger_config = optional(object({
      parallelism              = optional(number)
      replica_completion_count = optional(number)
    }))
    event_trigger_config = optional(object({
      parallelism              = optional(number)
      replica_completion_count = optional(number)
      scale = optional(object({
        max_executions              = optional(number)
        min_executions              = optional(number)
        polling_interval_in_seconds = optional(number)
        rules = optional(object({
          name             = optional(string)
          custom_rule_type = optional(string)
          metadata         = optional(map(string))
          authentication = optional(object({
            secret_name       = optional(string)
            trigger_parameter = optional(string)
          }))
        }))
      }))
    }))
    schedule_trigger_config = optional(object({
      cron_expression          = optional(string)
      parallelism              = optional(number)
      replica_completion_count = optional(number)
    }))
  })
```

Default:

```json
{
  "manual_trigger_config": {
    "parallelism": 1,
    "replica_completion_count": 1
  }
}
```

## Outputs

The following outputs are exported:

### <a name="output_container_app_job_name"></a> [container\_app\_job\_name](#output\_container\_app\_job\_name)

Description: The name of the Container App Job.

### <a name="output_resource_id"></a> [resource\_id](#output\_resource\_id)

Description: The ID of the Container App Job.

## Modules

No modules.

<!-- markdownlint-disable-next-line MD041 -->
## Data Collection

The software may collect information about you and your use of the software and send it to Microsoft. Microsoft may use this information to provide services and improve our products and services. You may turn off the telemetry as described in the repository. There are also some features in the software that may enable you and Microsoft to collect data from users of your applications. If you use these features, you must comply with applicable law, including providing appropriate notices to users of your applications together with a copy of Microsoft’s privacy statement. Our privacy statement is located at <https://go.microsoft.com/fwlink/?LinkID=824704>. You can learn more about data collection and use in the help documentation and our privacy statement. Your use of the software operates as your consent to these practices.
<!-- END_TF_DOCS -->