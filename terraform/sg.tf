#---------------------------------------------------#
# Security Group                                    #
#---------------------------------------------------#
resource "aws_security_group" "allow_tls" {
  name        = "sg_internship_vladislav"
  description = "Allow TLS inbound traffic"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "sg_internship_vladislav"
  }
}
