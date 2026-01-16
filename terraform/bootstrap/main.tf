terraform {
  required_providers {
    yandex = {
      source  = "yandex-cloud/yandex"
      version = "~> 0.140"
    }
  }
}

provider "yandex" {
  token     = var.yc_token
  cloud_id  = var.cloud_id
  folder_id = var.folder_id
  zone      = var.zone
}

resource "yandex_storage_bucket" "tfstate" {
  bucket        = var.bucket_name
  folder_id     = var.folder_id
  force_destroy = true
}

resource "yandex_iam_service_account_static_access_key" "tfstate_key" {
  service_account_id = var.sa_id
  description        = "static key for terraform state in Object Storage"
}
