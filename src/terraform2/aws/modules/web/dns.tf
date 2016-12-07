
resource "aws_route53_zone" "routing_to_zone" {
  name = "${var.domain}"
}


//resource "aws_route53_zone_association" "dns_association" {
//  vpc_id = ""
//  zone_id = ""
//}

//resource "aws_route53_health_check" "dns_health_check" {
//  type = ""
//}