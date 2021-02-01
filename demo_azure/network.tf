resource "azurerm_virtual_network" "vnet" {
  name                = "${var.prefix}-vnet"
  address_space       = var.vnet_cidr
  location            = var.location
  resource_group_name = azurerm_resource_group.main-rg.name
}

resource "azurerm_subnet" "subnet" {
  name                      = "${var.prefix}-subnet"
  address_prefixes          = var.subnet_cidr
  virtual_network_name      = azurerm_virtual_network.vnet.name
  resource_group_name       = azurerm_resource_group.main-rg.name
}

resource "azurerm_network_security_group" "subnet-nsg" {
  name                = "${var.prefix}-subnet-nsg"
  location            = var.location
  resource_group_name = azurerm_resource_group.main-rg.name
}

resource "azurerm_network_security_rule" "subnet-nsg-AllowSSH" {
  name                        = "AllowSSH"
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "22"
  source_address_prefixes     = var.external_ssh_allowed_access
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.main-rg.name
  network_security_group_name = azurerm_network_security_group.subnet-nsg.name
}

resource "azurerm_network_security_rule" "subnet-nsg-AllowExternalAccess" {
  name                         = "AllowExternalAccess"
  priority                     = 101
  direction                    = "Inbound"
  access                       = "Allow"
  protocol                     = "Tcp"
  source_port_range            = "*"
  destination_port_ranges      = ["80", "443", "3000", "4646", "5601", "8080-8083", "8181", "8200", "8500", "9080", "9090", "9093", "20000-32000"]
  source_address_prefixes      = var.external_ssh_allowed_access
  destination_address_prefixes = var.vnet_cidr
  description                  = "Allow http and ssh access to Gateway VM"
  resource_group_name          = azurerm_resource_group.main-rg.name
  network_security_group_name  = azurerm_network_security_group.subnet-nsg.name
}

resource "azurerm_network_security_rule" "subnet-nsg-AllowInternalAccessTcp" {
  name                         = "AllowInternalAccessTcp"
  priority                     = 102
  direction                    = "Inbound"
  access                       = "Allow"
  protocol                     = "Tcp"
  source_port_range            = "*"
  destination_port_ranges      = ["22", "80", "443", "53", "4646-4648", "8080-8083", "8181", "8200", "8300-8301", "8500", "8502", "8600", "9080", "9099", "9100", "20000-32000", "50000"]
  source_address_prefixes      = var.vnet_cidr
  destination_address_prefixes = var.vnet_cidr
  description                  = "Allow http access to Gateway VM"
  resource_group_name          = azurerm_resource_group.main-rg.name
  network_security_group_name  = azurerm_network_security_group.subnet-nsg.name
}

resource "azurerm_network_security_rule" "subnet-nsg-AllowInternalAccessUdp" {
  name                         = "AllowInternalAccessUdp"
  priority                     = 103
  direction                    = "Inbound"
  access                       = "Allow"
  protocol                     = "Udp"
  source_port_range            = "*"
  destination_port_ranges      = ["53", "4648", "8301", "8600"]
  source_address_prefixes      = var.vnet_cidr
  destination_address_prefixes = var.vnet_cidr
  description                  = "Allow http access to Gateway VM"
  resource_group_name          = azurerm_resource_group.main-rg.name
  network_security_group_name  = azurerm_network_security_group.subnet-nsg.name
}

resource "azurerm_network_security_rule" "subnet-nsg-DENY-All" {
  name                        = "DENY-All"
  priority                    = 4096
  direction                   = "Inbound"
  access                      = "Deny"
  protocol                    = "*"
  source_port_range           = "*"
  destination_port_range      = "*"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  description                 = "Deny All Access"
  resource_group_name         = azurerm_resource_group.main-rg.name
  network_security_group_name = azurerm_network_security_group.subnet-nsg.name
}

resource "azurerm_subnet_network_security_group_association" "subnet" {
  subnet_id                 = azurerm_subnet.subnet.id
  network_security_group_id = azurerm_network_security_group.subnet-nsg.id
}