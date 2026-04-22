variable "project" {
  type    = string
  default = "epicbook"
}

variable "location" {
  type    = string
  default = "canadacentral"
}

variable "resource_group_name" {
  type    = string
  default = "kalu_RG"
}

variable "vm_size_deploy" {
  type    = string
  default = "Standard_B2s"
}

variable "admin_username" {
  type    = string
  default = "azureuser"
}

variable "my_ip" {
  type    = string
  default = ""
}

variable "agent_public_ip" {
  type = string
}

variable "acr_sku" {
  type    = string
  default = "Basic"
}
