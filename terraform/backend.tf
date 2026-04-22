terraform {
  backend "azurerm" {
    resource_group_name  = "kalu_RG"
    storage_account_name = "tfstaterxnuj8ib"
    container_name       = "tfstate"
    key                  = "epicbook.tfstate"
    use_azuread_auth     = true
  }
}
