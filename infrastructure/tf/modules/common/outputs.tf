output "public_subnets" {
  value       = module.vpc.public_subnets
  description = "a list of the all public subnet 1"
}

output "vpc_id" {
  value = module.vpc.vpc_id
  description = "The ID of the VPC"
}

output "sqs_queue_url" {
  value = aws_sqs_queue.polybot-queue.id
  description = "The ID of the VPC"
}

output "dynamodb_table_name" {
  value = aws_dynamodb_table.polybot-table.name
  description = "The table's name"
}

output "bucket_name" {
  value = aws_s3_bucket.telebot.bucket
  description = "The table's name"
}
