terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=3.0.0"
    }
    azapi = {
      source  = "azure/azapi"
      version = "1.9"
    }
    azuread = {
      source  = "hashicorp/azuread"
      version = "~> 2.15.0"
    }
    spacelift = {
      source = "spacelift.io/spacelift-io/spacelift"
    }
  }
}

provider "azurerm" {
  features {}
}

provider "azapi" {
}

provider "azuread" {
  tenant_id = "67a6b159-2ceb-48cd-a023-cc670d5570d7"
}