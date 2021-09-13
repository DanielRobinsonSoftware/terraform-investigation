##################################################################################
# Main Terraform file 
##################################################################################

##################################################################################
# RESOURCES
##################################################################################

resource "azurerm_resource_group" "rg" {
  name     = var.resource_group_name
  location = var.location
  tags = {
    environment = var.environment
  }
}

##################################################################################
# Storage Account
##################################################################################
resource "azurerm_storage_account" "storage_account" {
  name                     = var.basename
  resource_group_name      = azurerm_resource_group.rg.name
  account_tier             = "Standard"
  account_replication_type = "LRS"
  account_kind             = "StorageV2"

  location = var.location
  tags = {
    environment = var.environment
  }
}

resource "azurerm_storage_container" "storage_containers" {
  name                  = "sample"
  storage_account_name  = azurerm_storage_account.storage_account.name
  container_access_type = "private"
}

##################################################################################
# Function App
##################################################################################
resource "azurerm_application_insights" "logging" {
  name                = "${var.basename}-ai"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  application_type    = "web"
  tags = {
    environment = var.environment
  }
}

resource "azurerm_storage_account" "fxnstor" {
  name                     = "${var.basename}fx"
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = var.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  account_kind             = "StorageV2"
  tags = {
    environment = var.environment
  }
}

resource "azurerm_app_service_plan" "fxnapp" {
  name                = "${var.basename}-plan"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
  kind                = "functionapp"
  sku {
    tier = "Free"
    size = "F1"
  }
  tags = {
    environment = var.environment
  }
}

resource "azurerm_function_app" "fxn" {
  name                      = var.basename
  location                  = var.location
  resource_group_name       = var.resource_group_name
  app_service_plan_id       = azurerm_app_service_plan.fxnapp.id
  storage_account_name       = azurerm_storage_account.fxnstor.name
  storage_account_access_key = azurerm_storage_account.fxnstor.primary_access_key
  version                   = "~3"

  app_settings = {
    "KeyVaultUri" = "${azurerm_key_vault.keyvault.vault_uri}"
  }

  identity {
    type = "SystemAssigned"
  }

  lifecycle {
  }

  tags = {
    environment = var.environment
  }
}


##################################################################################
# Key Vault
##################################################################################

#Create KeyVault ID
resource "random_id" "key_vault_name" {
  byte_length = 5
  prefix      = "keyvault"
}

#Keyvault Creation
resource "azurerm_key_vault" "keyvault" {
  name                        = random_id.key_vault_name.hex
  location                    = var.location
  resource_group_name         = azurerm_resource_group.rg.name
  enabled_for_disk_encryption = true
  tenant_id                   = data.azurerm_client_config.current.tenant_id
  soft_delete_retention_days  = 7
  purge_protection_enabled    = false

  sku_name = "standard"
}

resource "azurerm_key_vault_access_policy" "keyvault_access_policy" {
  key_vault_id         = azurerm_key_vault.keyvault.id
  
  tenant_id = data.azurerm_client_config.current.tenant_id
  object_id = azurerm_function_app.fxn.identity.0.principal_id

  key_permissions = [
    "get",
  ]

  secret_permissions = [
    "get", "list",
  ]

  storage_permissions = [
    "get",
  ]
}

#Create Key Vault Secret
resource "azurerm_key_vault_secret" "movie_db_access_token" {
  name         = "movie-db-access-token"
  value        = var.movie_db_access_token
  key_vault_id = azurerm_key_vault.keyvault.id
}

##################################################################################
# Role Assignments
##################################################################################
// https://docs.microsoft.com/en-us/azure/role-based-access-control/built-in-roles#key-vault-secrets-user
resource "azurerm_role_assignment" "functionToKeyVaultSecret1" {
  scope                = azurerm_key_vault.keyvault.id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = azurerm_function_app.fxn.identity[0].principal_id
}

// https://docs.microsoft.com/en-us/azure/role-based-access-control/built-in-roles#storage-blob-data-reader
// allows for blobServices/generateUserDelegationKey and blobs/read
resource "azurerm_role_assignment" "functionToStorage1" {
  scope                = azurerm_storage_account.storage_account.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = azurerm_function_app.fxn.identity[0].principal_id
}

// https://docs.microsoft.com/en-us/azure/role-based-access-control/built-in-roles#storage-account-key-operator-service-role
// allows for listkeys/action and regeneratekey/action
resource "azurerm_role_assignment" "functionToStorage2" {
  scope                = azurerm_storage_account.storage_account.id
  role_definition_name = "Storage Account Key Operator Service Role"
  principal_id         = azurerm_function_app.fxn.identity[0].principal_id
}

// https://docs.microsoft.com/en-us/azure/role-based-access-control/built-in-roles#reader-and-data-access
// allows for storageAccounts/read
resource "azurerm_role_assignment" "functionToStorage3" {
  scope                = azurerm_storage_account.storage_account.id
  role_definition_name = "Reader and Data Access"
  principal_id         = azurerm_function_app.fxn.identity[0].principal_id
}

##################################################################################
# Outputs
##################################################################################

#Apply with:
#terraform apply -auto-approve -input=false -var-file=dev.tfvars

resource "local_file" "app_deployment_script" {
  content  = <<CONTENT
#!/bin/bash

az functionapp config appsettings set -n ${azurerm_function_app.fxn.name} -g ${azurerm_resource_group.rg.name} --settings "APPINSIGHTS_INSTRUMENTATIONKEY=""${azurerm_application_insights.logging.instrumentation_key}""" > /dev/null
cd ../src ; func azure functionapp publish ${azurerm_function_app.fxn.name} --csharp ; cd ../terraform
CONTENT
  filename = "./deploy_app.sh"
}
