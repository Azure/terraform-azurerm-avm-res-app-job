resource "azurerm_container_app_job" "this" {
  container_app_environment_id = var.container_app_environment_resource_id
  location                     = var.location
  name                         = var.name
  replica_timeout_in_seconds   = var.replica_timeout_in_seconds
  resource_group_name          = var.resource_group_name
  tags                         = var.tags

  dynamic "template" {
    for_each = [var.template]

    content {
      dynamic "container" {
        for_each = [template.value.container]

        content {
          cpu     = container.value.cpu
          image   = container.value.image
          memory  = container.value.memory
          name    = container.value.name
          args    = container.value.args
          command = container.value.command

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
          image   = init_container.value.image
          name    = init_container.value.name
          args    = init_container.value.args
          command = init_container.value.command
          cpu     = init_container.value.cpu
          memory  = init_container.value.memory

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
          storage_name = volume.value.storage_name
          storage_type = volume.value.storage_type
        }
      }
    }
  }
  dynamic "event_trigger_config" {
    for_each = var.trigger_config.event_trigger_config == null ? [] : [var.trigger_config.event_trigger_config]

    content {
      parallelism              = event_trigger_config.value.parallelism
      replica_completion_count = event_trigger_config.value.replica_completion_count
    }
  }
  dynamic "identity" {
    for_each = local.managed_identities.system_assigned_user_assigned

    content {
      type         = identity.value.type
      identity_ids = identity.value.user_assigned_resource_ids
    }
  }
  dynamic "manual_trigger_config" {
    for_each = var.trigger_config.manual_trigger_config == null ? [] : [var.trigger_config.manual_trigger_config]

    content {
      parallelism              = manual_trigger_config.value.parallelism
      replica_completion_count = manual_trigger_config.value.replica_completion_count
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
}
