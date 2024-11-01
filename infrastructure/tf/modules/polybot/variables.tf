
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
variable "alias_record" {
  type        = string
  description = "The full alias record"
}
variable "cert_arn" {
  type        = string
  description = "The full alias record"
}