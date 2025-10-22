variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "domain_name" {
  description = "Base domain name"
  type        = string
  default     = "mpc.run.place"
}

variable "kibana_domain" {
  description = "Kibana domain name"
  type        = string
  default     = "kibana.mpc.run.place"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "production"
}