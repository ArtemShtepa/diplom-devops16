variable "YC_SA_KEY" { default = "" }
variable "YC_CLOUD_ID" { default = "" }
variable "YC_FOLDER_ID" { default = "" }
variable "YC_ZONE" { default = "" }

terraform {
  required_providers {
    yandex = {
      source = "yandex-cloud/yandex"
    }
  }
  required_version = ">= 0.13"
}

provider "yandex" {
  service_account_key_file = var.YC_SA_KEY
  cloud_id  = var.YC_CLOUD_ID
  folder_id = var.YC_FOLDER_ID
  zone      = var.YC_ZONE
}
