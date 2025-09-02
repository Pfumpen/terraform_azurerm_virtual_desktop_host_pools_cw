resource "azurerm_virtual_desktop_host_pool_registration_info" "this" {
  count = try(var.host_pool.registration_info.enabled, false) ? 1 : 0

  hostpool_id     = azurerm_virtual_desktop_host_pool.this.id
  expiration_date = timeadd(timestamp(), "${try(var.host_pool.registration_info.duration_hours, 24)}h")
}
