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

data "aws_ami" "amazon-2" {
  most_recent = true

  filter {
    name   = "name"
    values = ["al2023-ami-2023.*-kernel-*-x86_64"]
  }
  owners = ["amazon"]
}


resource "aws_instance" "api" {
  instance_type               = "t2.nano"
  ami                         = data.aws_ami.amazon-2.id
  vpc_security_group_ids      = [aws_security_group.web_server_sg_tf.id]
  associate_public_ip_address = true
  key_name                    = aws_key_pair.webserver.key_name
  root_block_device {
    volume_type           = "gp2"
    volume_size           = "8"
    delete_on_termination = true
  }

  tags = {
    Name = "${random_pet.name.id}"
  }

  connection {
    type        = "ssh"
    host        = self.public_ip
    user        = var.ec2_user
    private_key = file(var.aws_key_pair.path_to_private_key)
    timeout     = "10m"
  }

  iam_instance_profile = aws_iam_instance_profile.app.name

  user_data = templatefile("init.tftpl", {
    bucket       = aws_s3_bucket.fib.id
    key          = aws_s3_object.app.id
    port         = var.port
    release_mode = var.release_mode
  })
  user_data_replace_on_change = true

  depends_on = [aws_s3_object.app]

  lifecycle {
    replace_triggered_by = [
      aws_s3_object.app.source_hash
    ]
  }
}

resource "aws_iam_instance_profile" "app" {
  name = "AppProfile"
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
  name               = "AppRole"
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
  key_name   = var.aws_key_pair.key_name
  public_key = var.aws_key_pair.public_key
}

data "aws_vpc" "default" {
  default = true
}

resource "aws_security_group" "web_server_sg_tf" {
  name        = "${random_pet.name.id}-sg"
  description = "SG for Fibonacci app"
  vpc_id      = data.aws_vpc.default.id
}

# resource "aws_security_group_rule" "allow_https" {
#   type              = "ingress"
#   description       = "HTTPS ingress"
#   from_port         = 443
#   to_port           = 443
#   protocol          = "tcp"
#   cidr_blocks       = ["0.0.0.0/0"]
#   security_group_id = aws_security_group.web_server_sg_tf.id
# }

resource "aws_security_group_rule" "allow_http" {
  type              = "ingress"
  description       = "HTTP ingress"
  from_port         = var.port
  to_port           = var.port
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
  bucket        = "${random_pet.name.id}-bucket"
  force_destroy = true
}

resource "aws_s3_object" "app" {
  bucket      = aws_s3_bucket.fib.id
  key         = var.app
  source      = var.app
  source_hash = filemd5(var.app)
}

resource "random_pet" "name" {
  prefix = "tf-fibonacci-app"
  length = 1
}