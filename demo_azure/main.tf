resource "azurerm_resource_group" "main-rg" {
  name      = var.resource_group_name
  location  = var.location
}

resource "tls_private_key" "vm_ssh_key" {
  algorithm = "RSA"
  rsa_bits = 4096
}

## Save the private key in the local workspace ##
resource "null_resource" "save-key" {
  triggers = {
    timestamp = timestamp()
  }

  provisioner "local-exec" {
    command = <<EOF
      mkdir -p .ssh
      echo "${tls_private_key.vm_ssh_key.private_key_pem}" > .ssh/id_rsa
      chmod 0600 .ssh/id_rsa
      echo "${tls_private_key.vm_ssh_key.public_key_openssh}" > .ssh/id_rsa.pub
      chmod 0644 .ssh/id_rsa.pub
EOF
  }
}

module "nomad-server" {
  source              = "./compute"
  prefix              = var.prefix
  subnet_id           = azurerm_subnet.subnet.id
  number              = 1
  type                = "nomad-server"
  vm_size             = "Standard_D2s_v3"

  resource_group_name = azurerm_resource_group.main-rg.name
  location            = var.location
  admin_user_name     = var.vm_username
  public_key_openssh  = tls_private_key.vm_ssh_key.public_key_openssh

  gateway_connection  = true 

  #cloud_init_template = data.template_cloudinit_config.stateful_config.rendered
}

module "nomad-client" {
  source              = "./compute"
  prefix              = var.prefix
  subnet_id           = azurerm_subnet.subnet.id
  number              = 3
  type                = "nomad-client"
  vm_size             = "Standard_D2s_v3"

  resource_group_name = azurerm_resource_group.main-rg.name
  location            = var.location
  admin_user_name     = var.vm_username
  public_key_openssh  = tls_private_key.vm_ssh_key.public_key_openssh

  gateway_connection  = false 

  #cloud_init_template = data.template_cloudinit_config.stateful_config.rendered
  depends_on = [
    module.nomad-server,
  ]
}


