variable "role_name" {
  type        = string
  default     = ""
  description = "Role name"
}

variable "ec2_key" {
  type        = string
  default     = "ec2-key"
}

variable "vpc_name" {
  type        = string
  default     = "VPC"
}

variable "main_vpc_cidr_block" {
  type        = string
  default     = "10.0.0.0/16"
}

variable "private_key_pem_sensitive" {
  type        = bool
  default     = true
}

variable "public_subnet_cidr_block" {
  type        = string
  default     = "10.0.1.0/24"
}

variable "availability_zone" {
  type        = string
  default     = "eu-west-1a"
  description = "Availability Zone for the public subnet"
}

variable "public_subnet_name" {
  type        = string
  default     = "PublicSubnet"
  description = "Name tag for the public subnet"
}

variable "igw_name" {
  type        = string
  default     = "IGW"
  description = "Name tag for the Internet Gateway"
}

variable "route_table_name" {
  type        = string
  default     = "PublicRouteTable"
  description = "Name tag for the public route table"
}

variable "security_group_name" {
  type        = string
  default     = "SG"
  description = "Name tag for the security group"
}

variable "security_group_description" {
  type        = string
  default     = "Security Group"
  description = "Description for the security group"
}

variable "ami_id" {
  type        = string
  default     = "ami-0720a3ca2735bf2fa"
  description = "AMI ID for the EC2 instance"
}

variable "instance_type" {
  type        = string
  default     = "t2.small"
  description = "Instance type for the EC2 instance"
}

variable "instance_name" {
  type        = string
  default     = ""
  description = "Name tag for the EC2 instance"
}