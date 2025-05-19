resource "azurerm_container_app_job" "this" {
  name                         = var.name
  location                     = var.location
  resource_group_name          = var.resource_group_name
  container_app_environment_id = var.container_app_environment_resource_id
  replica_timeout_in_seconds   = var.replica_timeout_in_seconds
  tags                         = var.tags

  dynamic "template" {
    for_each = [var.template]
    content {
      dynamic "container" {
        for_each = [template.value.container]
        content {
          name    = container.value.name
          image   = container.value.image
          cpu     = container.value.cpu
          memory  = container.value.memory
          command = container.value.command
          args    = container.value.args

          dynamic "env" {
            for_each = container.value.env == null ? [] : container.value.env

            content {
              name        = env.value.name
              secret_name = env.value.secret_name
              value       = env.value.value
            }
          }
        }
      }
      dynamic "init_container" {
        for_each = template.value.init_container == null ? [] : template.value.init_container
        content {
          name    = init_container.value.name
          image   = init_container.value.image
          cpu     = init_container.value.cpu
          memory  = init_container.value.memory
          command = init_container.value.command
          args    = init_container.value.args

          dynamic "env" {
            for_each = init_container.value.env == null ? [] : init_container.value.env

            content {
              name        = env.value.name
              secret_name = env.value.secret_name
              value       = env.value.value
            }
          }
        }
      }
      dynamic "volume" {
        for_each = template.value.volume == null ? [] : template.value.volume
        content {
          name         = volume.value.name
          storage_type = volume.value.storage_type
          storage_name = volume.value.storage_name
        }
      }
    }
  }

  dynamic "manual_trigger_config" {
    for_each = var.trigger_config.manual_trigger_config == null ? [] : [var.trigger_config.manual_trigger_config]
    content {
      parallelism              = manual_trigger_config.value.parallelism
      replica_completion_count = manual_trigger_config.value.replica_completion_count
    }
  }

  dynamic "event_trigger_config" {
    for_each = var.trigger_config.event_trigger_config == null ? [] : [var.trigger_config.event_trigger_config]
    content {
      parallelism              = event_trigger_config.value.parallelism
      replica_completion_count = event_trigger_config.value.replica_completion_count
    }
  }

  dynamic "schedule_trigger_config" {
    for_each = var.trigger_config.schedule_trigger_config == null ? [] : [var.trigger_config.schedule_trigger_config]
    content {
      cron_expression          = schedule_trigger_config.value.cron_expression
      parallelism              = schedule_trigger_config.value.parallelism
      replica_completion_count = schedule_trigger_config.value.replica_completion_count
    }
  }

  dynamic "identity" {
    for_each = local.managed_identities.system_assigned_user_assigned
    content {
      type         = identity.value.type
      identity_ids = identity.value.user_assigned_resource_ids
    }
  }
}
