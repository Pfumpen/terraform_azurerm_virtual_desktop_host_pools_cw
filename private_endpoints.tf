resource "azurerm_private_endpoint" "this" {
  for_each = var.private_endpoints

  name                = each.value.name != null ? each.value.name : "pep-${var.host_pool.name}-${each.key}"
  location            = var.host_pool.location
  resource_group_name = var.host_pool.resource_group_name
  subnet_id           = each.value.subnet_id
  tags                = var.host_pool.tags

  private_service_connection {
    name                           = "psc-${var.host_pool.name}-${each.key}"
    private_connection_resource_id = azurerm_virtual_desktop_host_pool.this.id
    is_manual_connection           = false
    subresource_names              = ["connection"]
  }

  dynamic "private_dns_zone_group" {
    for_each = try(each.value.private_dns_zone_group, null) != null ? [each.value.private_dns_zone_group] : []
    content {
      name                 = private_dns_zone_group.value.name
      private_dns_zone_ids = private_dns_zone_group.value.private_dns_zone_ids
    }
  }

  lifecycle {
    ignore_changes = [
      tags,
    ]
  }
}
