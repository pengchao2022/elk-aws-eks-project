output "kibana_dns_record" {
  description = "Kibana DNS record details"
  value       = aws_route53_record.kibana.fqdn
}

output "alb_dns_name" {
  description = "ALB DNS name"
  value       = var.alb_dns_name
}

output "domain_name" {
  description = "Domain name"
  value       = var.domain_name
}