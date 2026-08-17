########################################
# Rrivate endpoint + private DNS
# Additive only. Public access stays on; nothing breaks.
########################################

resource "azurerm_private_dns_zone" "blob" {
  name                = "privatelink.blob.core.windows.net"
  resource_group_name = azurerm_resource_group.lab.name
}

# Without this link, the zone exists but no VNet can see it.
resource "azurerm_private_dns_zone_virtual_network_link" "blob" {
  name                  = "link-vnet-tfstate-lab"
  resource_group_name   = azurerm_resource_group.lab.name
  private_dns_zone_name = azurerm_private_dns_zone.blob.name
  virtual_network_id    = azurerm_virtual_network.lab.id
  registration_enabled  = false
}

resource "azurerm_private_endpoint" "state_blob" {
  name                = "pe-${azurerm_storage_account.state.name}-blob"
  location            = azurerm_resource_group.lab.location
  resource_group_name = azurerm_resource_group.lab.name
  subnet_id           = azurerm_subnet.private_endpoints.id

  private_service_connection {
    name                           = "psc-blob"
    private_connection_resource_id = azurerm_storage_account.state.id
    subresource_names              = ["blob"]
    is_manual_connection           = false
  }

  # This is what writes the A record into the zone. Omit it and you get an
  # endpoint with no DNS — which only fails after you disable public access.
  private_dns_zone_group {
    name                 = "default"
    private_dns_zone_ids = [azurerm_private_dns_zone.blob.id]
  }
}

output "state_private_ip" {
  value = azurerm_private_endpoint.state_blob.private_service_connection[0].private_ip_address
}
