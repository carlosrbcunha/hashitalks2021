output "disk_ids" {
    value = azurerm_managed_disk.csi-disk.*.id
}

output "disk_volume_names" {
    value = azurerm_managed_disk.csi-disk.*.tags[*]["Volume_name"]
}

output "disks" {
    value = azurerm_managed_disk.csi-disk[*]
}