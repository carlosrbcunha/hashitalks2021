locals {
  my_name            = "${var.prefix}-${var.type}"
  my_deployment      = var.prefix
  my_admin_user_name = var.admin_user_name
  my_private_key     = "vm_id_rsa"
}

resource "azurerm_network_interface" "generic-nic" {
  count                   = (var.gateway_connection == true) ? 0 : var.number
  name                    = "${local.my_name}-${count.index}-nic"
  location                = var.location
  resource_group_name     = var.resource_group_name
  internal_dns_name_label = "${local.my_name}-${count.index}"

  ip_configuration {
    name                          = "${local.my_name}-${count.index}-ip"
    subnet_id                     = var.subnet_id
    private_ip_address_allocation = "Dynamic"
  }

  tags = {
    Name        = "${local.my_name}-${count.index}"
    Deployment  = local.my_deployment
    Prefix      = var.prefix
    Location    = var.location
    Terraform   = "true"
  }
}

resource "azurerm_network_interface" "generic-nic-with-external-ip" {
  count               = (var.gateway_connection == true) ? 1 : 0
  name                = "${local.my_name}-${count.index}-nic"
  location            = var.location
  resource_group_name = var.resource_group_name

  ip_configuration {
    name                          = "${local.my_name}-${count.index}-ip"
    subnet_id                     = var.subnet_id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.gateway-ip[count.index].id
  }

  tags = {
    Name        = "${local.my_name}-${count.index}"
    Prefix      = var.prefix
    Location    = var.location
    Terraform   = "true"
  }
}

resource "azurerm_public_ip" "gateway-ip" {
  count               = (var.gateway_connection == true) ? 1 : 0
  name                = "${local.my_name}-${count.index}-gateway-ip"
  location            = var.location
  resource_group_name = var.resource_group_name
  allocation_method   = "Static"

  tags = {
    Name        = "${local.my_name}-${count.index}"
    Prefix      = var.prefix
    Location    = var.location
    Terraform   = "true"
  }
}

resource "azurerm_linux_virtual_machine" "generic-vm" {
  count                            = var.number
  name                             = "${local.my_name}-${count.index}-vm"
  location                         = var.location
  resource_group_name              = var.resource_group_name
  size                             = var.vm_size
  network_interface_ids            = var.gateway_connection == true ? [azurerm_network_interface.generic-nic-with-external-ip[count.index].id] : [azurerm_network_interface.generic-nic[count.index].id]
  disable_password_authentication  = true
  admin_username                   = local.my_admin_user_name
  computer_name                    = "${var.type}-${count.index}"
  custom_data                      = var.cloud_init_template

  source_image_reference {
    offer     = "0001-com-ubuntu-server-focal"
    publisher = "Canonical"
    sku       = "20_04-lts-gen2"
    version   = "latest"
  }

  os_disk {
    name                    = "${local.my_name}-${count.index}-os"
    caching                 = "ReadWrite"
    storage_account_type    = "Premium_LRS"
    disk_size_gb            = var.os_disk_size
  }

  admin_ssh_key {
    username   = local.my_admin_user_name
    public_key = var.public_key_openssh
  }

  tags = {
    Name          = "${local.my_name}-${count.index}"
    Prefix        = var.prefix
    Location      = var.location
    Terraform     = "true"
  }
}
