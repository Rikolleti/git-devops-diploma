bucket  = "azmamedov-16012026-tfstate"
key     = "infra/terraform.tfstate"
region  = "ru-central1"

endpoints = {
  s3 = "https://storage.yandexcloud.net"
}

skip_region_validation      = true
skip_credentials_validation = true
skip_metadata_api_check     = true
force_path_style            = true
skip_requesting_account_id  = true
