terraform {
  required_version = ">= 1.8.1"

  required_providers {
    azurerm = {
      source                = "hashicorp/azurerm"
      version               = "~> 4.0"
      configuration_aliases = [azurerm.dns]
    }
  }
}
