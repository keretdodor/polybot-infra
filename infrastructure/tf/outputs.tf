output "sqs_queue_url" {
  value       = module.common.sqs_queue_url
  description = "The sqs queue"
}
output "dynamodb_table_name" {
  value       = module.common.dynamodb_table_name
  description = "The table's name"
}
output "bucket_name" {
  value       = module.common.bucket_name
  description = "The table's name"
}
output "alias_record" {
  value       = module.polybot.alias_record
  description = "The table's name"
}
output "polybot_public_ips" {
  value = module.polybot.polybot_public_ips
}
output "ami_ip" {
  value = module.yolo5.ami_ip
}