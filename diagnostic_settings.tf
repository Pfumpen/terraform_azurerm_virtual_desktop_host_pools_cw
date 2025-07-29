locals {
  # Defines the diagnostic presets for the Virtual Desktop Host Pool.
  diagnostics_presets = {
    basic = {
      logs    = ["Checkpoint", "Error", "Management"]
      metrics = [] # No metrics are available for this resource type.
    },
    detailed = {
      logs    = ["Checkpoint", "Error", "Management", "Connection", "HostRegistration", "AgentHealthStatus"]
      metrics = [] # No metrics are available for this resource type.
    },
    custom = {
      logs    = var.diagnostics_custom_logs
      metrics = var.diagnostics_custom_metrics
    }
  }

  # Determines the active log and metric categories based on the selected diagnostics_level.
  active_log_categories    = lookup(local.diagnostics_presets, var.diagnostics_level, { logs = [] }).logs
  active_metric_categories = lookup(local.diagnostics_presets, var.diagnostics_level, { metrics = [] }).metrics

  # A global switch to enable or disable diagnostic settings based on the diagnostics_level.
  global_diagnostics_enabled = var.diagnostics_level != "none"
}

resource "azurerm_monitor_diagnostic_setting" "this" {
  # Creates the diagnostic setting only if the global switch is enabled.
  count = local.global_diagnostics_enabled ? 1 : 0

  name                           = "diag-${var.host_pool.name}"
  target_resource_id             = azurerm_virtual_desktop_host_pool.this.id
  log_analytics_workspace_id     = try(var.diagnostic_settings.log_analytics_workspace_id, null)
  eventhub_authorization_rule_id = try(var.diagnostic_settings.eventhub_authorization_rule_id, null)
  storage_account_id             = try(var.diagnostic_settings.storage_account_id, null)

  # Dynamically enables the specified log categories.
  dynamic "enabled_log" {
    for_each = toset(local.active_log_categories)
    content {
      category = enabled_log.value
    }
  }

  # Dynamically enables the specified metric categories.
  dynamic "enabled_metric" {
    for_each = toset(local.active_metric_categories)
    content {
      category = enabled_metric.value
    }
  }
}
