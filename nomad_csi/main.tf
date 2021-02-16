# Get data from infra terraform state
data "terraform_remote_state" "infra" {
  backend = "local"

  config = {
    path = "../${var.infra}/terraform.tfstate"
  }
}

data "azurerm_resource_group" "main-rg" {
  name = data.terraform_remote_state.infra.outputs.rg_name
}

provider "nomad" {
  address = data.terraform_remote_state.infra.outputs.nomad_address
}
# Render CSI related Nomad Jobs

resource "nomad_job" "nomad_csi_node_job" {
  jobspec = templatefile("templates/plugin-azure-node.tmpl", {
    tenant_id = var.tenant_id
    subscription_id = var.subscription_id
    client_id = var.client_id
    client_secret = var.client_secret
    resource_group_name = data.azurerm_resource_group.main-rg.name
    location = data.azurerm_resource_group.main-rg.location
    prefix = var.prefix
    csi_version = var.csi_version
    csi_plugin_id = var.csi_plugin_id
  })
  detach = false
  purge_on_destroy = true
  depends_on = [data.terraform_remote_state.infra , data.azurerm_resource_group.main-rg]
}

resource "time_sleep" "wait_for_controller_job" {
  depends_on = [nomad_job.nomad_csi_node_job]

  create_duration = "10s"
}

resource "nomad_job" "nomad_csi_controller_job" {
  jobspec = templatefile("templates/plugin-azure-controller.tmpl", {
    tenant_id = var.tenant_id
    subscription_id = var.subscription_id
    client_id = var.client_id
    client_secret = var.client_secret
    resource_group_name = data.azurerm_resource_group.main-rg.name
    location = data.azurerm_resource_group.main-rg.location
    prefix = var.prefix
    csi_version = var.csi_version
    csi_plugin_id = var.csi_plugin_id
  })
  detach = false
  purge_on_destroy = true
  depends_on = [time_sleep.wait_for_controller_job]
}

data "nomad_plugin" "azure_disk" {
  plugin_id        = var.csi_plugin_id
  wait_for_healthy = true
  depends_on = [nomad_job.nomad_csi_node_job]
}

resource "nomad_volume" "csi_volumes" {
  count           = length(data.terraform_remote_state.infra.outputs.managed_disks)
  type            = "csi"
  namespace       = "default"
  plugin_id       = var.csi_plugin_id
  volume_id       = data.terraform_remote_state.infra.outputs.managed_disks[count.index].tags.Volume_name
  name            = data.terraform_remote_state.infra.outputs.managed_disks[count.index].tags.Volume_name
  external_id     = data.terraform_remote_state.infra.outputs.managed_disks[count.index].id
  access_mode     = "single-node-writer"
  attachment_mode = "file-system"

  depends_on      = [data.nomad_plugin.azure_disk]
}