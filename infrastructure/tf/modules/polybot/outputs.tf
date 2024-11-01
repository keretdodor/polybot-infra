output "alias_record" {
  value = aws_route53_record.lb-alias.name
  description = "The table's name"
}
output "polybot_public_ips" {
  value       = aws_instance.polybot[*].public_ip
  description = "The public IP addresses of the EC2 instances."
}