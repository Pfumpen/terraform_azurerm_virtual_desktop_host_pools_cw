locals {
  global_diagnostics_enabled = var.diagnostics_level != "none"

  # Securely capture the data source output. This local will be `null` if diagnostics are disabled.
  data_source_output = local.global_diagnostics_enabled ? data.azurerm_monitor_diagnostic_categories.this[0] : null

  # --- Pre-calculated lists for the resource block ---

  # Determine active log category GROUPS ('allLogs', 'audit')
  active_log_groups = local.global_diagnostics_enabled && var.diagnostics_level == "all" && contains(try(local.data_source_output.log_category_groups, []), "allLogs") ? ["allLogs"] : (
    local.global_diagnostics_enabled && var.diagnostics_level == "audit" && contains(try(local.data_source_output.log_category_groups, []), "audit") ? ["audit"] : []
  )

  # Determine active INDIVIDUAL logs ('custom' or fallback for 'all')
  active_individual_logs = local.global_diagnostics_enabled && var.diagnostics_level == "custom" ? var.diagnostics_custom_logs : (
    local.global_diagnostics_enabled && var.diagnostics_level == "all" && !contains(try(local.data_source_output.log_category_groups, []), "allLogs") ? try(local.data_source_output.logs, []) : []
  )

  # Determine active metrics (only if the resource supports metrics)
  active_metrics = local.global_diagnostics_enabled && length(try(local.data_source_output.metrics, [])) > 0 ? var.diagnostics_custom_metrics : []
}

# This data source is only executed when diagnostics are enabled.
data "azurerm_monitor_diagnostic_categories" "this" {
  count = local.global_diagnostics_enabled ? 1 : 0

  # IMPORTANT: Change this to the ID of the primary resource of your module
  resource_id = azurerm_virtual_desktop_host_pool.this.id
}

resource "azurerm_monitor_diagnostic_setting" "this" {
  count = local.global_diagnostics_enabled ? 1 : 0

  # IMPORTANT: Use a unique name for the diagnostic setting
  name                           = "diag-${var.host_pool.name}"
  target_resource_id             = data.azurerm_monitor_diagnostic_categories.this[0].resource_id
  log_analytics_workspace_id     = try(var.diagnostic_settings.log_analytics_workspace_id, null)
  eventhub_authorization_rule_id = try(var.diagnostic_settings.eventhub_authorization_rule_id, null)
  storage_account_id             = try(var.diagnostic_settings.storage_account_id, null)

  # The dynamic blocks below consume the pre-calculated lists from locals.

  dynamic "enabled_log" {
    for_each = toset(local.active_log_groups)
    content {
      category_group = enabled_log.value
    }
  }

  dynamic "enabled_log" {
    for_each = toset(local.active_individual_logs)
    content {
      category = enabled_log.value
    }
  }

  dynamic "metric" {
    for_each = toset(local.active_metrics)
    content {
      category = metric.value
    }
  }
}
