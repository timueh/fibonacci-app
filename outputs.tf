output "ec2_public_access" {
  value = aws_instance.api.public_dns
}