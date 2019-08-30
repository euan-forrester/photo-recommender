
resource "aws_route53_zone" "primary" {
    name = "${var.api_server_domain}"
    force_destroy = true
}

resource "aws_route53_record" "api_server" {
    zone_id = "${aws_route53_zone.primary.zone_id}"
    name    = "${var.api_server_domain}"
    type    = "A"

    alias {
        name                   = "${aws_lb.api_server.dns_name}"
        zone_id                = "${aws_lb.api_server.zone_id}"
        evaluate_target_health = true
    }
}