
resource "aws_route53_zone" "primary" {
    name = "${var.application_domain}"
    force_destroy = true
}

resource "aws_route53_record" "api_server" {
    zone_id = "${aws_route53_zone.primary.zone_id}"
    name    = "${var.application_domain}"
    type    = "A"

    alias {
        name                   = "${aws_cloudfront_distribution.application.domain_name}"
        zone_id                = "${aws_cloudfront_distribution.application.hosted_zone_id}"
        evaluate_target_health = true
    }
}