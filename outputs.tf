output "id" {
  description = "The ID of the Virtual Desktop Host Pool."
  value       = azurerm_virtual_desktop_host_pool.this.id
}

output "name" {
  description = "The name of the Virtual Desktop Host Pool."
  value       = azurerm_virtual_desktop_host_pool.this.name
}

output "registration_info_token" {
  description = "The registration token for the host pool."
  value       = try(azurerm_virtual_desktop_host_pool_registration_info.this[0].token, null)
  sensitive   = true
}

output "private_endpoints" {
  description = "A map of all created private endpoint objects, including their IDs and FQDNs."
  value       = azurerm_private_endpoint.this
  sensitive   = true
}
