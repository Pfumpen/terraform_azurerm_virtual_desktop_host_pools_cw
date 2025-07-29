# Azure Virtual Desktop Host Pools Terraform Module

This Terraform module creates and manages Azure Virtual Desktop Host Pools.

## Features

- Creates a Virtual Desktop Host Pool with flexible configuration.
- Conditionally creates registration info for the host pool.
- Conditionally creates diagnostic settings for the host pool.
- Manages role assignments on the host pool's scope.
- Creates multiple private endpoints for the host pool.
- Applies a merged map of user-defined and default tags to all taggable resources.

## Usage

### Basic Example

This example creates a simple, pooled host pool with only the required attributes.

```hcl
module "virtual_desktop_host_pool" {
  source = "git::https://github.com/Pfumpen/terraform_azurerm_virtual_desktop_host_pools_cw.git"

  host_pool = {
    name                = "avd-hp-basic-example"
    location            = "West Europe"
    resource_group_name = "rg-avd-basic-example"
    type                = "Pooled"
    load_balancer_type  = "BreadthFirst"
  }
}
```

### Complete Example

This example demonstrates all features of the module, including diagnostic settings, role assignments, and private endpoints.

```hcl
module "virtual_desktop_host_pool" {
  source = "git::https://github.com/Pfumpen/terraform_azurerm_virtual_desktop_host_pools_cw.git"

  host_pool = {
    name                             = "avd-hp-complete-example"
    location                         = "West Europe"
    resource_group_name              = "rg-avd-complete-example"
    type                             = "Pooled"
    load_balancer_type               = "DepthFirst"
    friendly_name                    = "Complete AVD Host Pool"
    description                      = "A comprehensive example of a Virtual Desktop Host Pool."
    validate_environment             = true
    start_vm_on_connect              = true
    custom_rdp_properties            = "audiocapturemode:i:1;audiomode:i:0;"
    maximum_sessions_allowed         = 50
    preferred_app_group_type         = "Desktop"
    public_network_access            = "Disabled"
    tags = {
      environment = "production"
      cost-center = "IT"
    }
    scheduled_agent_updates = {
      enabled  = true
      timezone = "W. Europe Standard Time"
      schedules = [
        {
          day_of_week = "Saturday"
          hour_of_day = 2
        },
        {
          day_of_week = "Sunday"
          hour_of_day = 2
        }
      ]
    }
    registration_info = {
      expiration_date = "2025-12-31T23:59:59Z"
    }
  }

  diagnostics_level = "detailed"
  diagnostic_settings = {
    log_analytics_workspace_id = azurerm_log_analytics_workspace.this.id
  }

  role_assignments = {
    desktop_virtualization_user = {
      role_definition_name = "Desktop Virtualization User"
      principal_id         = "00000000-0000-0000-0000-000000000000" # Replace with a valid Principal ID
    }
  }

  private_endpoints = {
    hostpool = {
      subnet_id         = azurerm_subnet.this.id
      subresource_names = ["hostpool"]
      private_dns_zone_group = {
        name                 = "default"
        private_dns_zone_ids = [azurerm_private_dns_zone.this.id]
      }
    }
  }
}
```

## Variables

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| `host_pool` | Configuration for the Virtual Desktop Host Pool. All core settings are defined here. | `object` | n/a | yes |
| `diagnostics_level` | Defines the detail level for diagnostics. Possible values: 'none', 'basic', 'detailed', 'custom'. | `string` | `"basic"` | no |
| `diagnostic_settings` | A map containing the destination IDs for diagnostic settings. | `object` | `{}` | no |
| `diagnostics_custom_logs` | A list of log categories to enable when diagnostics_level is 'custom'. | `list(string)` | `[]` | no |
| `diagnostics_custom_metrics` | A list of metric categories to enable when diagnostics_level is 'custom'. | `list(string)` | `[]` | no |
| `role_assignments` | A map of role assignments to apply to the host pool. | `map(object)` | `{}` | no |
| `private_endpoints` | A map of private endpoints to create for the host pool. | `map(object)` | `{}` | no |
| `enable_telemetry` | Enable telemetry collection for the module. | `bool` | `true` | no |

### `host_pool` object

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| `name` | The name of the Virtual Desktop Host Pool. | `string` | n/a | yes |
| `location` | The Azure location where the Virtual Desktop Host Pool should exist. | `string` | n/a | yes |
| `resource_group_name` | The name of the Resource Group where the Virtual Desktop Host Pool should exist. | `string` | n/a | yes |
| `type` | The type of the Virtual Desktop Host Pool. | `string` | n/a | yes |
| `load_balancer_type` | The load balancer type for the host pool. | `string` | n/a | yes |
| `friendly_name` | The friendly name for the host pool. | `string` | `null` | no |
| `description` | The description for the host pool. | `string` | `null` | no |
| `validate_environment` | Whether to validate the environment. | `bool` | `false` | no |
| `start_vm_on_connect` | Whether to start the VM on connect. | `bool` | `false` | no |
| `custom_rdp_properties` | The custom RDP properties for the host pool. | `string` | `null` | no |
| `personal_desktop_assignment_type` | The personal desktop assignment type for the host pool. | `string` | `null` | no |
| `public_network_access` | The public network access for the host pool. | `string` | `"Enabled"` | no |
| `maximum_sessions_allowed` | The maximum number of sessions allowed. | `number` | `null` | no |
| `preferred_app_group_type` | The preferred app group type for the host pool. | `string` | `"Desktop"` | no |
| `vm_template` | The VM template for the host pool. | `string` | `null` | no |
| `tags` | A map of tags to assign to the resource. | `map(string)` | `{}` | no |
| `scheduled_agent_updates` | The scheduled agent updates for the host pool. | `object` | `{}` | no |
| `registration_info` | The registration info for the host pool. | `object` | `null` | no |

### `diagnostic_settings` object

When `diagnostics_level` is not `none`, exactly one of the following attributes must be specified.

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| `log_analytics_workspace_id` | The ID of the Log Analytics Workspace to send diagnostics to. | `string` | `null` | no |
| `eventhub_authorization_rule_id` | The ID of the Event Hub Authorization Rule to send diagnostics to. | `string` | `null` | no |
| `storage_account_id` | The ID of the Storage Account to send diagnostics to. | `string` | `null` | no |

### `role_assignments` map

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| `role_definition_name` | The name of the role definition. | `string` | n/a | yes |
| `principal_id` | The ID of the principal. | `string` | n/a | yes |
| `description` | The description of the role assignment. | `string` | `null` | no |
| `condition` | The condition of the role assignment. | `string` | `null` | no |
| `condition_version` | The condition version of the role assignment. | `string` | `null` | no |

### `private_endpoints` map

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| `name` | The name of the private endpoint. | `string` | `pep-${var.host_pool.name}-${each.key}` | no |
| `subnet_id` | The ID of the subnet. | `string` | n/a | yes |
| `subresource_names` | A list of sub-resource names. | `list(string)` | n/a | yes |
| `private_dns_zone_group` | The private DNS zone group. | `object` | `null` | no |

## Outputs

| Name | Description |
|------|-------------|
| `id` | The ID of the Virtual Desktop Host Pool. |
| `name` | The name of the Virtual Desktop Host Pool. |
| `registration_info_token` | The registration token for the host pool. |
| `private_endpoints` | A map of all created private endpoint objects, including their IDs and FQDNs. |
