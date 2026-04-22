terraform {
  backend "azurerm" {
    resource_group_name  = "kalu_RG"
    storage_account_name = "tfstate8bpa061m"
    container_name       = "tfstate"
    key                  = "epicbook.tfstate"
    use_azuread_auth     = true
  }
}
