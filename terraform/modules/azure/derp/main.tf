locals {
  create_firewall_rule = var.firewall_rule_name == ""
  create_static_ip      = var.public_derp && var.existing_ip == ""

  ip_address = local.create_static_ip ? azurerm_public_ip.derp_ip[0].ip_address : var.existing_ip
}

# Static Public IP (only if needed)
resource "azurerm_public_ip" "derp_ip" {
  count               = local.create_static_ip ? 1 : 0
  name                = "${var.name_prefix}-derp-ip"
  location            = var.location
  resource_group_name = var.resource_group_name
  allocation_method   = "Static"
  sku                 = "Standard"
}

# Network Security Group
resource "azurerm_network_security_group" "derp_nsg" {
  count               = local.create_firewall_rule ? 1 : 0
  name                = "${var.name_prefix}-derp-nsg"
  location            = var.location
  resource_group_name = var.resource_group_name

  security_rule {
    name                       = "Allow-UDP-3478"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Udp"
    source_port_range          = "*"
    destination_port_range     = "3478"
    source_address_prefixes    = var.ingress_cidr_blocks
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Allow-TCP-443"
    priority                   = 1002
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefixes    = var.ingress_cidr_blocks
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Allow-SSH"
    priority                   = 1003
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefixes    = var.ingress_cidr_blocks
    destination_address_prefix = "*"
  }
}

# Network Interface
resource "azurerm_network_interface" "derp_nic" {
  name                = "${var.name_prefix}-nic"
  location            = var.location
  resource_group_name = var.resource_group_name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = var.subnet_id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = local.create_static_ip ? azurerm_public_ip.derp_ip[0].id : null
  }

  tags = var.tags
}

# NSG Association
resource "azurerm_network_interface_security_group_association" "derp_nsg_assoc" {
  count                     = local.create_firewall_rule ? 1 : 0
  network_interface_id      = azurerm_network_interface.derp_nic.id
  network_security_group_id = azurerm_network_security_group.derp_nsg[0].id
}

# SSH Key
resource "tls_private_key" "ssh_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

# VM
resource "azurerm_linux_virtual_machine" "derp_vm" {
  name                = "${var.name_prefix}-derp-vm"
  resource_group_name = var.resource_group_name
  location            = var.location
  size                = var.vm_size
  admin_username      = "ubuntu"
  network_interface_ids = [
    azurerm_network_interface.derp_nic.id,
  ]

  disable_password_authentication = true

  admin_ssh_key {
    username   = "ubuntu"
    public_key = tls_private_key.ssh_key.public_key_openssh
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts"
    version   = "latest"
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
    disk_size_gb         = var.volume_size
    name                 = "${var.name_prefix}-osdisk"
  }

  custom_data = base64encode(templatefile("${path.module}/derp-init.tpl", {
    hostname    = var.hostname
    public_derp = var.public_derp
  }))

  tags = var.tags
}
