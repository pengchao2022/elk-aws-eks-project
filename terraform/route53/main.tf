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
    key            = "elk-eks/route53.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-locks"
    encrypt        = true
  }
}

provider "aws" {
  region = var.aws_region
}

# Route53 Hosted Zone for awsmpc.asia
resource "aws_route53_zone" "main" {
  name = var.domain_name
  force_destroy = true  # 添加这一行

  tags = {
    Name        = var.domain_name
    Environment = var.environment
    Project     = "elk-stack"
  }
}

# Optional: Create a test record to verify the zone is working
resource "aws_route53_record" "test" {
  count = var.create_test_record ? 1 : 0

  zone_id = aws_route53_zone.main.zone_id
  name    = "test.${var.domain_name}"
  type    = "A"
  ttl     = 300
  records = ["8.8.8.8"]
}