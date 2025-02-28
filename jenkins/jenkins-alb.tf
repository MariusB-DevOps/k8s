resource "aws_lb" "jenkins_alb" {
  name               = "jenkins-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.jenkins_alb_sg.id]
  subnets            = module.vpc.public_subnets

  enable_deletion_protection = false
}

resource "aws_lb_listener" "jenkins_https" {
  load_balancer_arn = aws_lb.jenkins_alb.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy       = "ELBSecurityPolicy-2016-08"
  certificate_arn  = aws_acm_certificate.jenkins_cert.arn

  default_action {
    type = "forward"
    target_group_arn = aws_lb_target_group.jenkins_tg.arn
  }
}

resource "aws_lb_target_group" "jenkins_tg" {
  name     = "jenkins-tg"
  port     = 8080
  protocol = "HTTP"
  vpc_id   = module.vpc.vpc_id
  target_type = "ip"

  health_check {
    path                = "/login"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }
}

resource "aws_acm_certificate" "jenkins_cert" {
  domain_name       = "jenkins.k8s.it.com"
  validation_method = "DNS"
}

resource "aws_route53_record" "jenkins_cert_validation" {
  for_each = {
    for dvo in aws_acm_certificate.jenkins_cert.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  zone_id = aws_route53_zone.k8s_it_com.zone_id
  name    = each.value.name
  type    = each.value.type
  ttl     = 60
  records = [each.value.record]
}

resource "aws_route53_record" "jenkins_dns" {
  zone_id = aws_route53_zone.k8s_it_com.zone_id
  name    = "jenkins.k8s.it.com"
  type    = "A"

  alias {
    name                   = aws_lb.jenkins_alb.dns_name
    zone_id                = aws_lb.jenkins_alb.zone_id
    evaluate_target_health = true
  }
}

resource "aws_security_group" "jenkins_alb_sg" {
  vpc_id = module.vpc.vpc_id

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

