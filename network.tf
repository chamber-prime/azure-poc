########################################
# Network — VNet and subnets
########################################

resource "azurerm_virtual_network" "lab" {
  name                = "vnet-tfstate-lab"
  address_space       = ["10.10.0.0/16"]
  location            = azurerm_resource_group.lab.location
  resource_group_name = azurerm_resource_group.lab.name
}

resource "azurerm_subnet" "private_endpoints" {
  name                              = "snet-private-endpoints"
  resource_group_name               = azurerm_resource_group.lab.name
  virtual_network_name              = azurerm_virtual_network.lab.name
  address_prefixes                  = ["10.10.1.0/27"]
  private_endpoint_network_policies = "Disabled"
}

# Reserved for whatever consumer ends up living inside the VNet later —
# a self-hosted runner, a container instance, or a jump box. Empty subnets
# cost nothing, and carving address space now avoids a renumber later.
resource "azurerm_subnet" "workload" {
  name                 = "snet-workload"
  resource_group_name  = azurerm_resource_group.lab.name
  virtual_network_name = azurerm_virtual_network.lab.name
  address_prefixes     = ["10.10.0.0/24"]
}
