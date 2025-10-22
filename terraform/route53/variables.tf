variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "domain_name" {
  description = "Domain name for the hosted zone"
  type        = string
  default     = "awsmpc.asia"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "production"
}

variable "create_test_record" {
  description = "Whether to create a test DNS record"
  type        = bool
  default     = false
}