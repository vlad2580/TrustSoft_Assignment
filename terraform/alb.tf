#-------------------------------#
# Load Balancer                 #
#-------------------------------#

# Load Balancer (ALB)
resource "aws_lb" "app_lb" {
  name                       = var.alb_name
  internal                   = false
  load_balancer_type         = "application"
  security_groups            = [aws_security_group.allow_tls.id]
  subnets                    = [aws_subnet.publicSB1.id, aws_subnet.publicSB2.id]
  enable_deletion_protection = false

  tags = {
    Name = "alb_internship_vladislav"
  }
}

# Target Group
resource "aws_lb_target_group" "tg" {
  name     = var.target_group_name
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id

  health_check {
    path                = "/"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }

  tags = {
    Name = "target_group_internship_vladislav"
  }
}

# Listener
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.app_lb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.tg.arn
  }
}

resource "aws_lb_target_group_attachment" "tg_attachment" {
  count            = 2
  target_group_arn = aws_lb_target_group.tg.arn
  target_id        = aws_instance.web_server[count.index].id
  port             = 80
}
