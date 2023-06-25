output "ec2_public_access" {
  value = aws_instance.api.public_dns
}

output "address" {
  value = "curl http://${aws_instance.api.public_dns}:${var.port}/fibonacci/:n (replace :n by a number)"
}