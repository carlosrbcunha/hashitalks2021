variable "infra" {
    description = "Folder of demo infra used"
}

variable "prefix" {
  description = "Project prefix"
  default = "HashiTalks-Demo"
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
    default = "latest"
}

variable "csi_plugin_id" {
    description = "Name of csi plugin"
    default = "az-disk0"
}