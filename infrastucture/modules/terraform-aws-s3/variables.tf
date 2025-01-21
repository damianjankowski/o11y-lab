variable "name" {
  description = "The name of the S3 bucket"
  type        = string
}

variable "tags" {
  description = "The tags to apply to the S3 bucket"
  type        = map(string)
  default     = {}
}

variable "versioning_status" {
  description = "Enable or disable bucket versioning"
  type        = string
  default     = "Enabled"
}

variable "server_side_encryption_configuration" {
  description = "Map containing server-side encryption configuration."
  type        = any
  default     = {}
}

variable "expected_bucket_owner" {
  description = "The account ID of the expected bucket owner"
  type        = string
  default     = null
}

variable "force_destroy" {
  description = "Set to true to allow deletion of non-empty S3 bucket"
  type        = bool
  default     = false
}
