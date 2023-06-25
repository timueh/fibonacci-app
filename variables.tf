variable "region" {
  type        = string
  default     = "us-east-1"
  description = "AWS region to deploy to"
}

variable "port" {
  type        = number
  default     = 8000
  description = "port to which to deploy"
}

variable "release_mode" {
  type        = string
  default     = "debug"
  description = "release mode of gin gonic api"
  validation {
    condition     = var.release_mode == "debug" || var.release_mode == "release" || var.release_mode == "test"
    error_message = "release mode must be 'debug', 'test', or 'release'"
  }
}

variable "app" {
  type        = string
  description = "name of binary to execute"
}

variable "aws_key_pair" {
  type = object({
    key_name            = string
    public_key          = string
    path_to_private_key = string
  })
  description = "key used to connect to ec2; you must possess the matching private key"
}

variable "ec2_user" {
  type        = string
  default     = "ec2-user"
  description = "default ec2 user"
}