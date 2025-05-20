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

variable "replica_timeout_in_seconds" {
  type        = number
  default     = 300
  description = "The timeout in seconds for the job to complete."
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
