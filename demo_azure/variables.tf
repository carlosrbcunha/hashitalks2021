
variable "resource_group_name" {
  description = "Azure resource group name"
  default = "HashiTalks-Demo"
}

variable "location" {
  description = "The default Azure region for the resource provisioning"
  default = "westeurope"
}

variable "vnet_cidr" {
  description = "CIDR block for Virtual Network"
  default = ["10.0.0.0/24"]
}

variable "subnet_cidr" {
  description = "CIDR block for Subnet within a Virtual Network"
  default = ["10.0.0.0/24"]
}

variable "vm_username" {
  description = "Enter admin username to SSH into Linux VM"
  default     = "demo-user"
}

variable "prefix" {
  description = "Project prefix"
  default = "HashiTalks-Demo"
}

variable "external_ssh_allowed_access" {
  description = "Range of addresses that can access via ssh externally to solution external IP"
  default     = ["88.157.236.36", "213.205.72.110", "213.205.68.220", "88.157.222.244","10.92.132.0/22","10.190.0.0/21","10.190.60.0/24","10.190.32.0/22","10.92.136.0/22"]
}

variable "managed_disks" {
    description = "Disk created to be managed by CSI in Nomad"
    type = list(object({
        volume_name = string
        disk_size   = number
        type        = string
    }))
}

variable "client_id" {
    description = "Azure client ID"
}

variable "client_secret" {
    description = "Azure client secret"
}

variable "subscription_id" {
    description = "Azure subscription ID"
}

variable "tenant_id" {
    description = "Azure tenant ID"
}

variable "csi_version" {
    description = "Azure CSI version"
    default = "v0.9.0"
}

variable "csi_plugin_id" {
    description = "Name of csi plugin"
    default = "az-disk0"
}