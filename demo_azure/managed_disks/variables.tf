variable "prefix" {}

variable "location" {
  description = "The default Azure region for the resource provisioning"
}

variable "rg_name" {
  description = "Azure resource group name"
}

variable "create_option" {
  default     = "Empty"
  description = "Disk creation option"
}

variable "managed_disks" {
  type = list(object({
    volume_name = string
    disk_size   = number
    type        = string
  }))
}
