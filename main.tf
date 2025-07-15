resource "azurerm_container_app_job" "this" {
  container_app_environment_id = var.container_app_environment_resource_id
  location                     = var.location
  name                         = var.name
  replica_retry_limit          = var.replica_retry_limit
  replica_timeout_in_seconds   = var.replica_timeout_in_seconds
  resource_group_name          = var.resource_group_name
  tags                         = var.tags
  workload_profile_name        = var.workload_profile_name

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

          dynamic "liveness_probe" {
            for_each = container.value.liveness_probe == null ? [] : container.value.liveness_probe

            content {
              failure_count_threshold = liveness_probe.value.failure_count_threshold
              host                    = liveness_probe.value.host
              initial_delay           = liveness_probe.value.initial_delay
              interval_seconds        = liveness_probe.value.interval_seconds
              path                    = liveness_probe.value.path
              port                    = liveness_probe.value.port
              timeout                 = liveness_probe.value.timeout
              transport               = liveness_probe.value.transport

              dynamic "header" {
                for_each = liveness_probe.value.header == null ? [] : liveness_probe.value.header

                content {
                  name  = header.value.name
                  value = header.value.value
                }
              }
            }
          }

          dynamic "readiness_probe" {
            for_each = container.value.readiness_probe == null ? [] : container.value.readiness_probe

            content {
              failure_count_threshold = readiness_probe.value.failure_count_threshold
              host                    = readiness_probe.value.host
              interval_seconds        = readiness_probe.value.interval_seconds
              path                    = readiness_probe.value.path
              port                    = readiness_probe.value.port
              success_count_threshold = readiness_probe.value.success_count_threshold
              timeout                 = readiness_probe.value.timeout
              transport               = readiness_probe.value.transport

              dynamic "header" {
                for_each = readiness_probe.value.header == null ? [] : readiness_probe.value.header

                content {
                  name  = header.value.name
                  value = header.value.value
                }
              }
            }
          }

          dynamic "startup_probe" {
            for_each = container.value.startup_probe == null ? [] : container.value.startup_probe

            content {
              failure_count_threshold = startup_probe.value.failure_count_threshold
              host                    = startup_probe.value.host
              interval_seconds        = startup_probe.value.interval_seconds
              path                    = startup_probe.value.path
              port                    = startup_probe.value.port
              timeout                 = startup_probe.value.timeout
              transport               = startup_probe.value.transport

              dynamic "header" {
                for_each = startup_probe.value.header == null ? [] : startup_probe.value.header

                content {
                  name  = header.value.name
                  value = header.value.value
                }
              }
            }
          }

          dynamic "volume_mounts" {
            for_each = container.value.volume_mounts == null ? [] : container.value.volume_mounts

            content {
              name = volume_mounts.value.name
              path = volume_mounts.value.path
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

      dynamic "scale" {
        for_each = event_trigger_config.value.scale == null ? [] : [event_trigger_config.value.scale]

        content {
          max_executions              = scale.value.max_executions
          min_executions              = scale.value.min_executions
          polling_interval_in_seconds = scale.value.polling_interval_in_seconds

          dynamic "rules" {
            for_each = scale.value.rules == null ? [] : scale.value.rules

            content {
              custom_rule_type = rules.value.custom_rule_type
              metadata         = rules.value.metadata
              name             = rules.value.name

              dynamic "authentication" {
                for_each = rules.value.authentication == null ? [] : [rules.value.authentication]

                content {
                  secret_name       = authentication.value.secret_name
                  trigger_parameter = authentication.value.trigger_parameter
                }
              }
            }
          }
        }
      }
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
  dynamic "secret" {
    for_each = var.secrets

    content {
      name                = secret.value.name
      identity            = secret.value.identity
      key_vault_secret_id = secret.value.key_vault_secret_id
      value               = secret.value.value
    }
  }
}
