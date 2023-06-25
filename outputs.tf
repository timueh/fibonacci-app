output "address" {
  value = "curl http://${aws_instance.api.public_dns}:${var.port}/fibonacci/:n (replace :n by a non-negative number)"
}

output "ssh_command" {
  value = "in case you want to ssh to your instance: ssh -i ${var.aws_key_pair.path_to_private_key} ${var.ec2_user}@${aws_instance.api.public_dns}"
}