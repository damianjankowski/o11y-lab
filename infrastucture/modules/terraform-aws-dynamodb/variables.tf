variable "table_name" {
  description = "The name of the DynamoDB table."
  type        = string
}

variable "billing_mode" {
  description = "The billing mode for the table. Either PROVISIONED or PAY_PER_REQUEST."
  type        = string
  default     = "PAY_PER_REQUEST"
}

variable "read_capacity" {
  description = "The number of read capacity units for the table (required if billing_mode is PROVISIONED)."
  type        = number
  default     = 5
}

variable "write_capacity" {
  description = "The number of write capacity units for the table (required if billing_mode is PROVISIONED)."
  type        = number
  default     = 5
}

variable "hash_key" {
  description = "The hash key for the table."
  type        = string
}

variable "range_key" {
  description = "The range key for the table."
  type        = string
  default     = null
}

variable "attributes" {
  description = "A list of attribute definitions for the table."
  type = list(object({
    name = string
    type = string
  }))
  default = []
}

variable "enable_ttl" {
  description = "Enable Time to Live (TTL) for the table."
  type        = bool
  default     = false
}

variable "ttl_attribute" {
  description = "The attribute name to use for TTL."
  type        = string
  default     = "TimeToExist"
}

variable "global_secondary_indexes" {
  description = "A list of global secondary indexes to create on the table."
  type = list(object({
    name               = string
    hash_key           = string
    range_key          = string
    projection_type    = string
    non_key_attributes = list(string)
    read_capacity      = number
    write_capacity     = number
  }))
  default = []
}

variable "tags" {
  description = "A map of tags to assign to the table."
  type        = map(string)
  default     = {}
}
