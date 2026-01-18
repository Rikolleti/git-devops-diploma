variable "yc_token" {
  description = "Yandex Cloud IAM token"
  type        = string
}

variable "cloud_id" {
  description = "Cloud ID"
  type        = string
}

variable "folder_id" {
  description = "Folder ID"
  type        = string
}

variable "zone" {
  description = "Availability zone"
  type        = string
  default     = "ru-central1-a"
}

variable "bucket_name" {
  description = "Bucket name"
  type        = string
}

variable "sa_id" {
  description = "Existing service account ID for creating static access keys"
  type        = string
}
