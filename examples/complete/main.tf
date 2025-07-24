provider "azurerm" {
  features {}
  subscription_id = "f965ed2c-e6b3-4c40-8bea-ea3505a01aa2"
}

resource "azurerm_resource_group" "this" {
  name     = "rg-avd-complete-example"
  location = "West Europe"
}

resource "azurerm_log_analytics_workspace" "this" {
  name                = "log-avd-complete-example"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  sku                 = "PerGB2018"
}

resource "azurerm_virtual_network" "this" {
  name                = "vnet-avd-complete-example"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
}

resource "azurerm_subnet" "this" {
  name                 = "snet-avd-complete-example"
  resource_group_name  = azurerm_resource_group.this.name
  virtual_network_name = azurerm_virtual_network.this.name
  address_prefixes     = ["10.0.1.0/24"]
  private_endpoint_network_policies = "Disabled"
}

resource "azurerm_private_dns_zone" "this" {
  name                = "privatelink.wvd.microsoft.com"
  resource_group_name = azurerm_resource_group.this.name
}

module "virtual_desktop_host_pool" {
  source = "../.."

  host_pool = {
    name                             = "avd-hp-complete-example"
    location                         = azurerm_resource_group.this.location
    resource_group_name              = azurerm_resource_group.this.name
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

  diagnostic_settings = {
    enabled                    = true
    log_analytics_workspace_id = azurerm_log_analytics_workspace.this.id
    log_categories = [
      "Checkpoint",
      "Error",
      "Management"
    ]
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
