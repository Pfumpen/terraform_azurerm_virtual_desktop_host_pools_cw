provider "azurerm" {
  features {}
  subscription_id = "f965ed2c-e6b3-4c40-8bea-ea3505a01aa2"
}

resource "azurerm_resource_group" "this" {
  name     = "rg-avd-basic-example"
  location = "West Europe"
}

module "virtual_desktop_host_pool" {
  source = "../.."

  host_pool = {
    name                = "avd-hp-basic-example"
    location            = azurerm_resource_group.this.location
    resource_group_name = azurerm_resource_group.this.name
    type                = "Pooled"
    load_balancer_type  = "BreadthFirst"
  }

  enable_telemetry = false
}
