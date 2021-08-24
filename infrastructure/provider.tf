terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 2.43.0"
    }
  }
}
provider "azurerm" {
  subscription_id = var.SUBSCRIPTION_ID
  tenant_id = var.TENANT_ID

  features {
      key_vault {
      purge_soft_delete_on_destroy = true
    }
  }  
}
