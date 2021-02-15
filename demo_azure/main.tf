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
    command = <<-EOF
      mkdir -p .ssh
      echo "${tls_private_key.vm_ssh_key.private_key_pem}" | tee .ssh/id_rsa >/dev/null
      chmod 0600 .ssh/id_rsa
      echo "${tls_private_key.vm_ssh_key.public_key_openssh}" | tee .ssh/id_rsa.pub >/dev/null
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
  location            = azurerm_resource_group.main-rg.location
  admin_user_name     = var.vm_username
  public_key_openssh  = tls_private_key.vm_ssh_key.public_key_openssh

  gateway_connection  = true 

  cloud_init_template = data.template_cloudinit_config.nomad_docker_config.rendered
}

module "nomad-client" {
  source              = "./compute"
  prefix              = var.prefix
  subnet_id           = azurerm_subnet.subnet.id
  number              = 3
  type                = "nomad-client"
  vm_size             = "Standard_D2s_v3"

  resource_group_name = azurerm_resource_group.main-rg.name
  location            = azurerm_resource_group.main-rg.location
  admin_user_name     = var.vm_username
  public_key_openssh  = tls_private_key.vm_ssh_key.public_key_openssh

  gateway_connection  = false 

  cloud_init_template = data.template_cloudinit_config.nomad_docker_config.rendered
  depends_on = [
    module.nomad-server
  ]
}

data "template_file" "nomad_docker_config" {
  template = file("templates/nomad-docker.tmpl")
}

data "template_cloudinit_config" "nomad_docker_config" {
  gzip          = true
  base64_encode = true

  part {
    content_type = "text/cloud-config"
    content      = data.template_file.nomad_docker_config.rendered
  }
}

resource "null_resource" "ssh_key_provision" {  
    depends_on = [module.nomad-server.gateway_public_ip, module.nomad-server, module.nomad-client, azurerm_network_security_rule.subnet-nsg-AllowInternalAccessTcp]
    provisioner "file" {
        content = tls_private_key.vm_ssh_key.private_key_pem
        destination = "~/.ssh/id_rsa"

        connection {
            type         = "ssh"
            user         = var.vm_username
            private_key  = tls_private_key.vm_ssh_key.private_key_pem
            host = module.nomad-server.gateway_public_ip[0]
        }
    }
    provisioner "remote-exec" {
        inline = [
            "chmod 0600 ~/.ssh/id_rsa",
            "curl -sLS https://get.hashi-up.dev | sh",
            "sudo install hashi-up /usr/local/bin/",
            "ssh-add ~/.ssh/id_rsa",
            "export SERVER_IP=${module.nomad-server.gateway_private_ip[0]}",
            "export AGENT_1_IP=${module.nomad-client.private_ip[0]}",
            "export AGENT_2_IP=${module.nomad-client.private_ip[1]}",
            "export AGENT_3_IP=${module.nomad-client.private_ip[2]}",
            "export USER=${var.vm_username}",
            "ssh-add -D",
            "ssh-add ~/.ssh/id_rsa",
            "sudo hashi-up consul install --ssh-target-addr $SERVER_IP --ssh-target-user $USER --server --client 0.0.0.0 --ssh-target-key ~/.ssh/id_rsa --config-file /tmp/consul-server.hcl",
            "sudo hashi-up consul install --ssh-target-addr $AGENT_1_IP --ssh-target-user $USER --retry-join $SERVER_IP --ssh-target-key ~/.ssh/id_rsa",
            "sudo hashi-up consul install --ssh-target-addr $AGENT_2_IP --ssh-target-user $USER --retry-join $SERVER_IP --ssh-target-key ~/.ssh/id_rsa",
            "sudo hashi-up consul install --ssh-target-addr $AGENT_3_IP --ssh-target-user $USER --retry-join $SERVER_IP --ssh-target-key ~/.ssh/id_rsa",
            "sudo /tmp/nomad-client.sh",
            "ssh -i ~/.ssh/id_rsa $USER@$AGENT_1_IP -o StrictHostKeyChecking=no '/tmp/nomad-client.sh'",
            "ssh -i ~/.ssh/id_rsa $USER@$AGENT_2_IP -o StrictHostKeyChecking=no '/tmp/nomad-client.sh'",
            "ssh -i ~/.ssh/id_rsa $USER@$AGENT_3_IP -o StrictHostKeyChecking=no '/tmp/nomad-client.sh'",
            "sudo hashi-up nomad install --ssh-target-addr $SERVER_IP --ssh-target-user $USER --server --client --bootstrap-expect 1 --ssh-target-key ~/.ssh/id_rsa --config-file /tmp/nomad-server.hcl",
            "sudo hashi-up nomad install --ssh-target-addr $AGENT_1_IP --ssh-target-user $USER --client --ssh-target-key ~/.ssh/id_rsa --config-file /tmp/nomad-client.hcl",
            "sudo hashi-up nomad install --ssh-target-addr $AGENT_2_IP --ssh-target-user $USER --client --ssh-target-key ~/.ssh/id_rsa --config-file /tmp/nomad-client.hcl",
            "sudo hashi-up nomad install --ssh-target-addr $AGENT_3_IP --ssh-target-user $USER --client --ssh-target-key ~/.ssh/id_rsa --config-file /tmp/nomad-client.hcl",
            "ssh -i ~/.ssh/id_rsa demo-user@$AGENT_1_IP -o StrictHostKeyChecking=no 'sudo rm /tmp/nomad-client.sh'",
            "ssh -i ~/.ssh/id_rsa demo-user@$AGENT_2_IP -o StrictHostKeyChecking=no 'sudo rm /tmp/nomad-client.sh'",
            "ssh -i ~/.ssh/id_rsa demo-user@$AGENT_3_IP -o StrictHostKeyChecking=no 'sudo rm /tmp/nomad-client.sh'",
            "sudo rm /tmp/nomad-client.sh",
            "sudo rm /tmp/nomad-server.hcl",
            "sudo rm /tmp/consul-server.hcl",
            "sudo rm /tmp/nomad-client.hcl",
        ]
        connection {
            type         = "ssh"
            user         = var.vm_username
            private_key  = tls_private_key.vm_ssh_key.private_key_pem
            host = module.nomad-server.gateway_public_ip[0]
        }
  }
}

##managed disk creation
module "csi-managed-disks" {
  source              = "./managed_disks"
  prefix              = var.prefix
  rg_name             = azurerm_resource_group.main-rg.name
  location            = azurerm_resource_group.main-rg.location
  managed_disks       = var.managed_disks
}

