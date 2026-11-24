
# Request an SSL/TLS certificate from AWS Certificate Manager
resource "aws_acm_certificate" "api" {
  domain_name       = "api.shiwanshu.site"
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }

  tags = {
    Name = "${var.project_name}-api-certificate"
  }
}

# Wait until the DNS validation record has been verified by AWS
resource "aws_acm_certificate_validation" "api" {
  certificate_arn = aws_acm_certificate.api.arn

  validation_record_fqdns = [
    for record in aws_acm_certificate.api.domain_validation_options :
    record.resource_record_name
  ]
}