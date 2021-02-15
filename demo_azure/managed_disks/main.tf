resource "azurerm_managed_disk" "csi-disk" {
  count                = length(var.managed_disks)
  name                 = "${var.prefix}-${var.managed_disks[count.index].volume_name}-disk"
  location             = var.location
  resource_group_name  = var.rg_name
  storage_account_type = var.managed_disks[count.index].type
  create_option        = var.create_option
  disk_size_gb         = var.managed_disks[count.index].disk_size

  tags = {
    Volume_name = var.managed_disks[count.index].volume_name
    Prefix      = var.prefix
    Location    = var.location
    Terraform   = "true"
  }
}