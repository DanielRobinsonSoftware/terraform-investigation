# SECRETS, PLEASE PROVIDE THESE VALUES IN A TFVARS FILE
variable "SUBSCRIPTION_ID" {}
variable "TENANT_ID" {}
variable "MOVIE_DB_ACCESS_TOKEN" {}

# GLOBAL VARIABLES
variable "RESOURCE_GROUP" {
  default = "movie-match"
}
variable "LOCATION" {
  default = "australiasoutheast"
}
