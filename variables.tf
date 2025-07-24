variable "host_pool" {
  description = "Configuration for the Virtual Desktop Host Pool. All core settings are defined here."
  type = object({
    name                               = string
    location                           = string
    resource_group_name                = string
    type                               = string
    load_balancer_type                 = string
    friendly_name                      = optional(string)
    description                        = optional(string)
    validate_environment               = optional(bool, false)
    start_vm_on_connect                = optional(bool, false)
    custom_rdp_properties              = optional(string)
    personal_desktop_assignment_type   = optional(string)
    public_network_access              = optional(string, "Enabled")
    maximum_sessions_allowed           = optional(number)
    preferred_app_group_type           = optional(string, "Desktop")
    vm_template                        = optional(string)
    tags                               = optional(map(string), {})
    scheduled_agent_updates = optional(object({
      enabled                   = optional(bool, false)
      timezone                  = optional(string, "UTC")
      use_session_host_timezone = optional(bool, false)
      schedules = optional(list(object({
        day_of_week = string
        hour_of_day = number
      })), [])
    }))
    registration_info = optional(object({
      expiration_date = string
    }))
  })
  nullable = false

  validation {
    condition     = length(var.host_pool.name) >= 3 && length(var.host_pool.name) <= 64
    error_message = "The host pool name must be between 3 and 64 characters long."
  }

  validation {
    condition     = var.host_pool.type == "Pooled" ? var.host_pool.personal_desktop_assignment_type == null : true
    error_message = "The 'personal_desktop_assignment_type' must not be set for 'Pooled' host pools."
  }

  validation {
    condition     = var.host_pool.type == "Personal" ? var.host_pool.personal_desktop_assignment_type != null : true
    error_message = "The 'personal_desktop_assignment_type' must be set for 'Personal' host pools."
  }

  validation {
    condition     = can(regex("^[a-zA-Z0-9][a-zA-Z0-9-]{1,62}[a-zA-Z0-9]$", var.host_pool.name))
    error_message = "The host pool name must only contain letters, numbers, and hyphens, and must not start or end with a hyphen."
  }

  validation {
    condition     = var.host_pool.load_balancer_type == "BreadthFirst" || var.host_pool.load_balancer_type == "DepthFirst" || var.host_pool.load_balancer_type == "Persistent"
    error_message = "The load balancer type must be one of 'BreadthFirst', 'DepthFirst', or 'Persistent'."
  }

  validation {
    condition     = try(var.host_pool.maximum_sessions_allowed, null) == null || (var.host_pool.maximum_sessions_allowed >= 1 && var.host_pool.maximum_sessions_allowed <= 999999)
    error_message = "The maximum sessions allowed must be between 1 and 999999."
  }

  validation {
    condition     = try(var.host_pool.scheduled_agent_updates.enabled, false) ? var.host_pool.scheduled_agent_updates.timezone != null : true
    error_message = "A timezone must be specified when scheduled agent updates are enabled."
  }

  validation {
    condition     = alltrue([
      for schedule in try(var.host_pool.scheduled_agent_updates.schedules, []) :
      contains(["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"], schedule.day_of_week) &&
      schedule.hour_of_day >= 0 && schedule.hour_of_day <= 23
    ])
    error_message = "Scheduled agent updates must have a valid day of the week and an hour between 0 and 23."
  }
}

variable "diagnostic_settings" {
  description = "A map of diagnostic settings to apply to the host pool."
  type = object({
    enabled                        = optional(bool, false)
    name                           = optional(string)
    log_analytics_workspace_id     = optional(string)
    storage_account_id             = optional(string)
    eventhub_authorization_rule_id = optional(string)
    log_categories                 = optional(set(string), [])
    metric_categories              = optional(set(string), ["AllMetrics"])
  })
  default = {}

  validation {
    condition = !try(var.diagnostic_settings.enabled, false) || (try(var.diagnostic_settings.enabled, false) && (
      try(var.diagnostic_settings.log_analytics_workspace_id, null) != null ||
      try(var.diagnostic_settings.storage_account_id, null) != null ||
      try(var.diagnostic_settings.eventhub_authorization_rule_id, null) != null
    ))
    error_message = "If enabled, a diagnostic setting must have at least one destination (log_analytics_workspace_id, storage_account_id, or eventhub_authorization_rule_id)."
  }
}

variable "role_assignments" {
  description = "A map of role assignments to apply to the host pool."
  type = map(object({
    role_definition_name = string
    principal_id         = string
    description          = optional(string)
    condition            = optional(string)
    condition_version    = optional(string)
  }))
  default = {}

  validation {
    condition = alltrue([
      for k, v in var.role_assignments :
      v.principal_id != null && v.role_definition_name != null
    ])
    error_message = "Each role assignment must have a 'principal_id' and a 'role_definition_name'."
  }
}

variable "private_endpoints" {
  description = "A map of private endpoints to create for the host pool."
  type = map(object({
    name                  = optional(string)
    subnet_id             = string
    subresource_names     = list(string)
    private_dns_zone_group = optional(object({
      name                 = string
      private_dns_zone_ids = list(string)
    }))
  }))
  default = {}

  validation {
    condition = alltrue([
      for k, v in var.private_endpoints :
      v.subnet_id != null && length(v.subresource_names) > 0
    ])
    error_message = "Each private endpoint must have a 'subnet_id' and at least one 'subresource_names'."
  }
}

variable "enable_telemetry" {
  description = "Enable telemetry collection for the module."
  type        = bool
  default     = true
}
