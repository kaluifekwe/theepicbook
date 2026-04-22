terraform {
  required_version = ">= 1.5.0"

  required_providers {
    azurerm = { source = "hashicorp/azurerm", version = "~> 3.100" }
    tls     = { source = "hashicorp/tls",     version = "~> 4.0" }
    local   = { source = "hashicorp/local",   version = "~> 2.5" }
    random  = { source = "hashicorp/random",  version = "~> 3.6" }
    http    = { source = "hashicorp/http",    version = "~> 3.4" }
  }
}

provider "azurerm" {
  features {}
}
