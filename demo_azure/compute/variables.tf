variable "prefix" {}

variable "number" {
  description = "Number of instances of this type to create"
}

variable "location" {
  description = "The default Azure region for the resource provisioning"
}

variable "resource_group_name" {
  description = "Azure resource group name"
}

variable "subnet_id" {
  description = "Subnet ID"
}

variable "os_disk_size" {
  default     = 30
  description = "Size of the os disk"
}

variable "type" {
  description = "VM type prefix"
}

variable "vm_size" {
  description = "Size of the Virtual Machine"
}

variable "public_key_openssh" {
  description = "Public key to inject into the VMs"
}

variable "admin_user_name" {
  description = "Admin username of the VM"
}

variable "cloud_init_template" {
  description = "Cloud-Init template"
  default     = ""
}

variable "gateway_connection" {
    description = "Gateway connection"
    default = false
}