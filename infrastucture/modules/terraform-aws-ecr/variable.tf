variable "ecr_name" {
  description = "The name of the ECR repository."
  type        = string
}

variable "image_tag_mutability" {
  description = "Determines whether image tags can be overwritten in the ECR repository. Valid values are 'MUTABLE' or 'IMMUTABLE'."
  type        = string
  default     = "MUTABLE"
}

variable "image_scanning_enabled" {
  description = "Enables or disables image scanning on image push in the ECR repository. Set to true to enable scanning."
  type        = bool
  default     = false
}

variable "force_delete" {
  description = "Enable or disable force deletion of the ECR."
  type        = bool
  default     = false
}
