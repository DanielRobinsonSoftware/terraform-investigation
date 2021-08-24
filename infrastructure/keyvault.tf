#Create KeyVault ID
resource "random_id" "key_vault_name" {
  byte_length = 5
  prefix      = "keyvault"
}

#Keyvault Creation
data "azurerm_client_config" "current" {}
resource "azurerm_key_vault" "movie_match_keyvault" {
  name                        = random_id.key_vault_name.hex
  location                    = var.LOCATION
  resource_group_name         = azurerm_resource_group.movie_match.name
  enabled_for_disk_encryption = true
  tenant_id                   = data.azurerm_client_config.current.tenant_id
  soft_delete_retention_days  = 7
  purge_protection_enabled    = false

  sku_name = "standard"

  access_policy {
    tenant_id = data.azurerm_client_config.current.tenant_id
    object_id = data.azurerm_client_config.current.object_id

    key_permissions = [
      "get",
    ]

    secret_permissions = [
      "get", "backup", "delete", "list", "purge", "recover", "restore", "set",
    ]

    storage_permissions = [
      "get",
    ]
  }
}

#Create Key Vault Secret
resource "azurerm_key_vault_secret" "movie_db_access_token" {
  name         = "movie-db-access-token"
  value        = var.MOVIE_DB_ACCESS_TOKEN
  key_vault_id = azurerm_key_vault.movie_match_keyvault.id
}