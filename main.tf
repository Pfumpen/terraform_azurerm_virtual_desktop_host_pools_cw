locals {
  tags = merge(
    { "deployment" = "terraform" },
    var.tags
  )
}

resource "azurerm_virtual_desktop_host_pool" "this" {
  name                             = var.host_pool.name
  location                         = var.host_pool.location
  resource_group_name              = var.host_pool.resource_group_name
  type                             = var.host_pool.type
  load_balancer_type               = var.host_pool.load_balancer_type
  friendly_name                    = try(var.host_pool.friendly_name, null)
  description                      = try(var.host_pool.description, null)
  validate_environment             = try(var.host_pool.validate_environment, false)
  start_vm_on_connect              = try(var.host_pool.start_vm_on_connect, false)
  custom_rdp_properties            = try(var.host_pool.custom_rdp_properties, null)
  personal_desktop_assignment_type = try(var.host_pool.personal_desktop_assignment_type, null)
  public_network_access            = try(var.host_pool.public_network_access, "Disabled")
  maximum_sessions_allowed         = try(var.host_pool.maximum_sessions_allowed, null)
  preferred_app_group_type         = try(var.host_pool.preferred_app_group_type, "Desktop")
  vm_template                      = try(var.host_pool.vm_template, null)
  tags                             = local.tags

  dynamic "scheduled_agent_updates" {
    for_each = try(var.host_pool.scheduled_agent_updates, null) != null ? [var.host_pool.scheduled_agent_updates] : []
    content {
      enabled                   = try(scheduled_agent_updates.value.enabled, false)
      timezone                  = try(scheduled_agent_updates.value.timezone, "UTC")
      use_session_host_timezone = try(scheduled_agent_updates.value.use_session_host_timezone, false)

      dynamic "schedule" {
        for_each = try(scheduled_agent_updates.value.schedules, [])
        content {
          day_of_week = schedule.value.day_of_week
          hour_of_day = schedule.value.hour_of_day
        }
      }
    }
  }

  lifecycle {
    ignore_changes = [
      tags,
    ]
  }
}
