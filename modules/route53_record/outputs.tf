output "domain_name" {
  value = aws_route53_record.example.name
}

output "certificate_arn" {
  value = aws_acm_certificate.example.arn
}
