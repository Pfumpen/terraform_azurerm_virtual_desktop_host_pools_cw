resource "azurerm_virtual_desktop_host_pool_registration_info" "this" {
  count = try(var.host_pool.registration_info, null) != null ? 1 : 0

  hostpool_id     = azurerm_virtual_desktop_host_pool.this.id
  expiration_date = var.host_pool.registration_info.expiration_date
}
