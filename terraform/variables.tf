variable "aws_region" {
  default = "us-east-1"
}

variable "lambda_execution_role" {
  default = "lambda-dynamodb-role"
  description = "IAM role for Lambda function execution"
}

variable "dynamodb_table_name" {
  default = "equipos"
}

variable "ec2_instance_type" {
  default = "t2.micro"
}

variable "ec2_key_name" {
  default = "devops"
}

variable "network-security-group-name" {
  default = "devops-sg"
}

variable "ubuntu-ami" {
  default = "ami-0f9de6e2d2f067fca"
}

variable "public-key" {
  default = "devops-key.pub"
}