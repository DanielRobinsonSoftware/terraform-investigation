# Secrets stored in .tfvars locally
variable "subscription_id" {}
variable "tenant_id" {}
variable "movie_db_access_token" {}

# Globals
variable "basename" {
  type        = string
  description = "The base name for all resources"
  default     = "moviematch20210831"
}

variable "resource_group_name" {
  type        = string
  description = "rg name. Use only lowercase letters and numbers"
  default     = "movie-match-rg"
}

variable "location" {
  type        = string
  description = "Azure region where to create resources."
  default     = "australiasoutheast"
}

variable "environment" {
  type        = string
  description = "The deployment environment description"
  default     = "dev"
}