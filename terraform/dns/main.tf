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
    key            = "elk-eks/dns.tfstate"
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

# Route53 Record for Kibana ALB
resource "aws_route53_record" "kibana" {
  zone_id = data.aws_route53_zone.main.zone_id
  name    = var.kibana_domain
  type    = "A"

  alias {
    name                   = var.alb_dns_name
    zone_id                = var.alb_zone_id
    evaluate_target_health = true
  }
}