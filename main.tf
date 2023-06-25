terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.16"
    }
  }

  required_version = ">= 1.2.0"
}

provider "aws" {
  region = var.region
}

locals {
  app = "fibonacci_app"
}

data "aws_ami" "amazon-2" {
  most_recent = true

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-ebs"]
  }
  owners = ["amazon"]
}


resource "aws_instance" "api" {
  instance_type               = "t2.micro"
  ami                         = "ami-022e1a32d3f742bd8"
  vpc_security_group_ids      = [aws_security_group.web_server_sg_tf.id]
  associate_public_ip_address = true
  key_name                    = aws_key_pair.webserver.key_name
  root_block_device {
    volume_type           = "gp2"
    volume_size           = "8"
    delete_on_termination = true
  }

  tags = {
    Name = "FibonacciAPI"
  }

  connection {
    type        = "ssh"
    host        = self.public_ip
    user        = "ec2-user"
    private_key = file("/Users/tillmann/.ssh/aws_ec2_fib_key")
    timeout     = "10m"
  }

  iam_instance_profile = aws_iam_instance_profile.app.name

  user_data                   = file("init.sh")
  user_data_replace_on_change = true

  depends_on = [aws_s3_object.app]

  lifecycle {
    replace_triggered_by = [
        aws_s3_object.app.source_hash
    ]
  }
}

resource "aws_iam_instance_profile" "app" {
  name = "FibAppProfile"
  role = aws_iam_role.app_role.name
}

data "aws_iam_policy_document" "assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "app_role" {
  name               = "FibAppRole"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

resource "aws_iam_role_policy_attachment" "s3_access" {
  role       = aws_iam_role.app_role.name
  policy_arn = aws_iam_policy.allow_s3.arn
}

resource "aws_iam_policy" "allow_s3" {
  name   = "AllowS3ForFibBucket"
  policy = data.aws_iam_policy_document.allow_s3.json
}

data "aws_iam_policy_document" "allow_s3" {
  statement {
    sid    = "AllowS3"
    effect = "Allow"
    actions = [
      "s3:GetObject",
      "s3:GetBucketLocation",
      "s3:ListBucket"
    ]
    resources = [
      aws_s3_bucket.fib.arn,
      "${aws_s3_bucket.fib.arn}/*",
    ]
  }
}

resource "aws_key_pair" "webserver" {
  key_name   = "aws_ec2_fib_key"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDKNaIOm0AxlEOZuzxt1PPAmJEXcjb5MiMvTsKrb9CJFx3BCGXwU8Dn4oo1Fybh5X9w8BhWm9b6vEE/96xM7PU5Ic7CA1khsHW3NrT9UrC4DuHj0CYxs/iM+B4mT3Uy873oWsAp/h3kDIIRxiL2Ld1kg7Z2uIBvySvXTYU2MhtruBNBJ6hf131ZHYI3W35Wwoxf/+vlLmWCVDgaI86ouGs+v9s6oBA0o8cAByHJ+NUZWJJaoURRRJ3QnQ6g0vS1gNZfBCWu2Dp7KRsrGCdIau6PaKWBTO2kJCCzaLp79I9iM356cPYUOu7Nyyi1kGQwsu9X80itPkWCcxjeRutLAnGd tillmann@MacBook-Pro"
}

data "aws_vpc" "default" {
  default = true
}

resource "aws_security_group" "web_server_sg_tf" {
  name        = "web-server-sg-https-tf"
  description = "Allow HTTPS to web server"
  vpc_id      = data.aws_vpc.default.id
}

resource "aws_security_group_rule" "allow_https" {
  type              = "ingress"
  description       = "HTTPS ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.web_server_sg_tf.id
}

resource "aws_security_group_rule" "allow_http" {
  type              = "ingress"
  description       = "HTTP ingress"
  from_port         = 8000
  to_port           = 8000
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.web_server_sg_tf.id
}

resource "aws_security_group_rule" "allow_ssh" {
  type              = "ingress"
  description       = "SSH ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.web_server_sg_tf.id
}

resource "aws_security_group_rule" "outbound" {
  type              = "egress"
  description       = "outgoing"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.web_server_sg_tf.id
}

resource "aws_s3_bucket" "fib" {
  bucket        = "tf-fibonacci-app-2809"
  force_destroy = true
}

resource "aws_s3_object" "app" {
  bucket      = aws_s3_bucket.fib.id
  key         = local.app
  source      = local.app
  source_hash = filemd5(local.app)
}