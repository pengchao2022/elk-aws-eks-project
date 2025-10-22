output "acm_certificate_arn" {
  description = "ACM certificate ARN"
  value       = aws_acm_certificate.kibana.arn
}

output "acm_certificate_domain" {
  description = "Certificate domain name"
  value       = aws_acm_certificate.kibana.domain_name
}

/*
output "acm_certificate_status" {
  description = "Certificate status"
  value       = aws_acm_certificate_validation.kibana.certificate_arn != "" ? "ISSUED" : "PENDING_VALIDATION"
}
*/
output "route53_zone_id" {
  description = "Route53 zone ID"
  value       = data.aws_route53_zone.main.zone_id
}