########################################
# Runner VM — SSH box and self-hosted GitHub Actions runner
#
# Lives in snet-workload, so it resolves the private DNS zone and reaches
# the storage account over the private endpoint. This is the machine that
# runs the public-access flip.
########################################

variable "my_public_ip" {
  description = "Public IP in CIDR form. Get it with: curl -s ifconfig.me"
  type        = string
  default = "49.37.251.70"
}

variable "ssh_public_key_path" {
  type    = string
  default = "~/.ssh/id_rsa.pub"
}

resource "azurerm_network_security_group" "runner" {
  name                = "nsg-runner"
  location            = azurerm_resource_group.lab.location
  resource_group_name = azurerm_resource_group.lab.name

  security_rule {
    name                       = "allow-ssh-from-me"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = var.my_public_ip
    destination_address_prefix = "*"
  }
}

resource "azurerm_subnet_network_security_group_association" "runner" {
  subnet_id                 = azurerm_subnet.workload.id
  network_security_group_id = azurerm_network_security_group.runner.id
}

resource "azurerm_public_ip" "runner" {
  name                = "pip-runner"
  location            = azurerm_resource_group.lab.location
  resource_group_name = azurerm_resource_group.lab.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_network_interface" "runner" {
  name                = "nic-runner"
  location            = azurerm_resource_group.lab.location
  resource_group_name = azurerm_resource_group.lab.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.workload.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.runner.id
  }
}

resource "azurerm_linux_virtual_machine" "runner" {
  name                  = "vm-runner"
  location              = azurerm_resource_group.lab.location
  resource_group_name   = azurerm_resource_group.lab.name
  size                  = "Standard_B2s"
  admin_username        = "azureuser"
  network_interface_ids = [azurerm_network_interface.runner.id]

  admin_ssh_key {
    username   = "azureuser"
    public_key = file(var.ssh_public_key_path)
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "ubuntu-24_04-lts"
    sku       = "server"
    version   = "latest"
  }

  # Reuse the identity that already holds Storage Blob Data Contributor,
  # rather than creating a system-assigned one and granting it again.
  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.github.id]
  }
}

output "runner_ssh" {
  value = "ssh azureuser@${azurerm_public_ip.runner.ip_address}"
}

output "runner_identity_client_id" {
  value = azurerm_user_assigned_identity.github.client_id
}
