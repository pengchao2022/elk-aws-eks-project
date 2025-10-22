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
  default     = "kibana.awsmpc.asia"
}

variable "alb_dns_name" {
  description = "ALB DNS name"
  type        = string
}

variable "alb_zone_id" {
  description = "ALB zone ID"
  type        = string
}