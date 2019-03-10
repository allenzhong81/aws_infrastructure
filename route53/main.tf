resource "aws_route53_zone" "main" {
  name = "${var.main_zone_name}"
}

resource "aws_route53_zone" "app" {
  name = "${var.app_zone_name}"
}

resource "aws_route53_record" "app-record" {
  zone_id = "${aws_route53_zone.main.zone_id}"
  name    = "${var.app_record_name}"
  type    = "CNAME"
  ttl     = "1"

  alias {
    name                   = "${var.alb_dns_name}"
    zone_id                = "${var.alb_zone_id}"
    evaluate_target_health = true
  }
}
