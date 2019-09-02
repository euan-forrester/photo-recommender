
resource "aws_route53_zone" "primary" {
    name = "${var.application_domain}"
    force_destroy = true
}

resource "aws_route53_record" "api_server" {
    zone_id = "${aws_route53_zone.primary.zone_id}"
    name    = "${var.application_domain}"
    type    = "A"

    alias {
        name                   = "${var.load_balancer_dns_name}"
        zone_id                = "${var.load_balancer_zone_id}"
        evaluate_target_health = true
    }
}