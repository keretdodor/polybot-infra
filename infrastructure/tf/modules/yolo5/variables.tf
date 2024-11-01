
variable "instance_type" {
   description = "Instance Type"
   type        = string
}

variable "key_name" {
   description = "key name"
   type        = string
}
variable "subnet_id" {
  type        = list(string)
  description = "List of subnets from the VPC module"
}

variable "vpc_id" {
  type        = string
  description = "The vpc id"
}

variable "dynamodb_table_name" {
   description = "table's name"
   type        = string
}

variable "sqs_queue_url" {
   description = "sqs url"
   type        = string
}
variable "s3_bucket" {
   description = "bucket name"
   type        = string
}

variable "alias_record" {
  type        = string
  description = "The full alias record"
}
variable "aws_region" {
  type        = string
  description = "the aws region"
}
variable "private_key" {
  type        = string
  description = "the aws region"
}
