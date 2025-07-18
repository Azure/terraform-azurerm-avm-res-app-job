variable "container_app_environment_resource_id" {
  type        = string
  description = "The ID of the Container App Environment to host this Container App."
  nullable    = false
}

variable "location" {
  type        = string
  description = "The Azure region where this and supporting resources should be deployed."
  nullable    = false
}

variable "name" {
  type        = string
  description = "The name for this Container App."
  nullable    = false
}

variable "resource_group_name" {
  type        = string
  description = "(Required) The name of the resource group in which the Container App Environment is to be created. Changing this forces a new resource to be created."
  nullable    = false
}

variable "template" {
  type = object({
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
      volume_mounts = optional(list(object({
        name = string
        path = string
      })))
    })))
    volume = optional(list(object({
      name         = optional(string)
      storage_type = optional(string)
      storage_name = optional(string)
    })))
  })
  description = <<DESCRIPTION
The template block describes the configuration for the Container App Job.
It defines the main container, optional init containers, resource requirements,
environment variables, probes (liveness, readiness, startup), and volume mounts.
Use this variable to specify the container image, CPU/memory, commands, arguments,
environment variables, and any additional configuration needed for the job's execution environment.
DESCRIPTION
}

variable "enable_telemetry" {
  type        = bool
  default     = true
  description = <<DESCRIPTION
This variable controls whether or not telemetry is enabled for the module.
For more information see <https://aka.ms/avm/telemetryinfo>.
If it is set to false, then no telemetry will be collected.
DESCRIPTION
}

variable "managed_identities" {
  type = object({
    system_assigned            = optional(bool, false)
    user_assigned_resource_ids = optional(set(string), [])
  })
  default     = {}
  description = <<DESCRIPTION
  Controls the Managed Identity configuration on this resource. The following properties can be specified:

  - `system_assigned` - (Optional) Specifies if the System Assigned Managed Identity should be enabled.
  - `user_assigned_resource_ids` - (Optional) Specifies a list of User Assigned Managed Identity resource IDs to be assigned to this resource.
  DESCRIPTION
  nullable    = false
}

variable "registries" {
  type = list(object({
    identity             = optional(string)
    password_secret_name = optional(string)
    server               = string
    username             = optional(string)
  }))
  default     = []
  description = <<DESCRIPTION
A list of container registries used by the Container App Job. Each registry can be defined with:
- `identity` - (Optional) The identity to use for accessing the registry. This can either be the Resource ID of a User Assigned Identity, or System for the System Assigned Identity.
- `password_secret_name` - (Optional) The name of the secret that contains the registry password.
- `server` - (Required) The hostname of the registry server.
- `username` - (Optional) The username to use for this registry.

NOTE: `identity` cannot be used with `username` and `password_secret_name`. When using `identity`, the identity must have access to the container registry.
DESCRIPTION

  validation {
    condition = alltrue([
      for registry in var.registries : (
        registry.identity != null ? (registry.username == null && registry.password_secret_name == null) : true
      )
    ])
    error_message = "When identity is provided, username and password_secret_name must not be provided."
  }
}

variable "replica_retry_limit" {
  type        = number
  default     = null
  description = "(Optional) The maximum number of retries before considering a Container App Job execution failed."
}

variable "replica_timeout_in_seconds" {
  type        = number
  default     = 300
  description = "The timeout in seconds for the job to complete."
}

variable "secrets" {
  type = list(object({
    name                = string
    identity            = optional(string)
    key_vault_secret_id = optional(string)
    value               = optional(string)
  }))
  default     = []
  description = <<DESCRIPTION
A list of secrets for the Container App Job. Each secret can be defined with:
- `name` - (Required) The secret name.
- `identity` - (Optional) The identity to use for accessing the Key Vault secret reference. This can either be the Resource ID of a User Assigned Identity, or System for the System Assigned Identity.
- `key_vault_secret_id` - (Optional) The ID of a Key Vault secret. This can be a versioned or version-less ID.
- `value` - (Optional) The value for this secret.

NOTE: `identity` must be used together with `key_vault_secret_id`. When using `key_vault_secret_id`, ignore_changes should be used to ignore any changes to value. `value` will be ignored if `key_vault_secret_id` and `identity` are provided.
DESCRIPTION

  validation {
    condition = alltrue([
      for secret in var.secrets : (
        secret.key_vault_secret_id != null ? secret.identity != null : true
      )
    ])
    error_message = "When key_vault_secret_id is provided, identity must also be provided."
  }
  validation {
    condition = alltrue([
      for secret in var.secrets : (
        secret.key_vault_secret_id != null || secret.value != null
      )
    ])
    error_message = "Either key_vault_secret_id or value must be provided for each secret."
  }
}

variable "tags" {
  type        = map(string)
  default     = null
  description = "(Optional) A mapping of tags to assign to the Container App Job."
}

variable "trigger_config" {
  type = object({
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
        rules = optional(list(object({
          name             = optional(string)
          custom_rule_type = optional(string)
          metadata         = optional(map(string))
          authentication = optional(object({
            secret_name       = optional(string)
            trigger_parameter = optional(string)
          }))
        })))
      }))
    }))
    schedule_trigger_config = optional(object({
      cron_expression          = optional(string)
      parallelism              = optional(number)
      replica_completion_count = optional(number)
    }))
  })
  default = {
    manual_trigger_config = {
      parallelism              = 1
      replica_completion_count = 1
    }
  }
  description = "Configuration for the trigger. Only one of manual_trigger_config, event_trigger_config, or schedule_trigger_config can be specified."

  validation {
    condition = (
      (var.trigger_config.manual_trigger_config != null ? 1 : 0) +
      (var.trigger_config.event_trigger_config != null ? 1 : 0) +
      (var.trigger_config.schedule_trigger_config != null ? 1 : 0)
    ) == 1
    error_message = "Only one of manual_trigger_config, event_trigger_config, or schedule_trigger_config can be specified."
  }
}

variable "workload_profile_name" {
  type        = string
  default     = null
  description = "(Optional) The name of the workload profile within the Container App Environment to place this Container App Job."
}
