terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  backend "s3" {
    bucket         = "terraformstatefile090909"
    key            = "elk-eks/acm.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-locks"
    encrypt        = true
  }
}

provider "aws" {
  region = var.aws_region
}

# Get Route53 zone data
data "aws_route53_zone" "main" {
  name         = var.domain_name
  private_zone = false
}

# ACM Certificate for Kibana
resource "aws_acm_certificate" "kibana" {
  domain_name       = var.kibana_domain
  validation_method = "DNS"

  subject_alternative_names = [
    "*.${var.domain_name}"
  ]

  tags = {
    Name        = "kibana-${var.kibana_domain}"
    Environment = var.environment
    Project     = "elk-stack"
  }

  lifecycle {
    create_before_destroy = true
  }
}

# DNS Validation Record
resource "aws_route53_record" "cert_validation" {
  for_each = {
    for dvo in aws_acm_certificate.kibana.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = data.aws_route53_zone.main.zone_id
}

# ACM Certificate Validation
resource "aws_acm_certificate_validation" "kibana" {
  certificate_arn         = aws_acm_certificate.kibana.arn
  validation_record_fqdns = [for record in aws_route53_record.cert_validation : record.fqdn]
}
