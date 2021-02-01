
variable "resource_group_name" {
  description = "Azure resource group name"
  default = "HashiTalk-Demo"
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

variable "vm_password" {
  description = "Enter admin password to SSH into VM"
  default     = "$up3rSecur3P@ss"
}

variable "prefix" {
  description = "Project prefix"
  default = "HashiTalk-Demo"
}

variable "external_ssh_allowed_access" {
  description = "Range of addresses that can access via ssh externally to solution external IP"
  default     = [""]
}