
resource "aws_instance" "polybot" {
  count = 2
  ami = data.aws_ami.ubuntu_ami.id
  instance_type = var.instance_type
  key_name = var.key_name

  subnet_id                   = var.subnet_id[count.index % length(var.subnet_id)]
  vpc_security_group_ids      = [aws_security_group.polybot-sg.id]
  associate_public_ip_address = true
  iam_instance_profile    = aws_iam_instance_profile.polybot-profile.name

 tags = {
    Name = "polybot-${count.index}"  # Adding index to the name for uniqueness

     }
    user_data = <<-EOF
              #!/bin/bash
              sudo apt-get update -y
              sudo apt-get install -y ansible
              EOF

  }


resource "aws_iam_instance_profile" "polybot-profile" {
  name = "polybot-profile"
  role = aws_iam_role.polybot-role.name
}

resource "aws_security_group" "polybot-sg" {
  name        = "polybot-sg"  
  description = "Allow SSH and HTTP traffic"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] 
  }  
    ingress {
    from_port   = 8443  
    to_port     = 8443
    protocol    = "tcp"
    cidr_blocks = ["149.154.160.0/20", "91.108.4.0/22"]
  }
    ingress {
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
  

}

resource "aws_route53_record" "lb-alias" {
  zone_id = data.aws_route53_zone.hosted_zone.zone_id 
  name    = var.alias_record
  type    = "A"

  alias {
    name                   = aws_lb.polybot.dns_name
    zone_id                = aws_lb.polybot.zone_id
    evaluate_target_health = true
  }
}

resource "aws_lb" "polybot" {
  name               = "polybot-wow"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.polybot-sg.id]
  subnets            = var.subnet_id

} 
resource "aws_lb_target_group" "polybot-tg" {
  name     = "polybot-tg"
  port     = 8443
  protocol = "HTTP"
  vpc_id   = var.vpc_id
  health_check {
    protocol            = "HTTP"
    path                = "/"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }
}

resource "aws_lb_target_group_attachment" "polybot-attachment" {
  for_each = {for idx in range(length(aws_instance.polybot)) : idx => aws_instance.polybot[idx].id}
  target_group_arn = aws_lb_target_group.polybot-tg.arn
  target_id        = each.value
  port             = 8443
}

resource "aws_lb_listener" "polybot-listener" {
  load_balancer_arn = aws_lb.polybot.arn
  port              = 8443
  protocol          = "HTTPS"
  certificate_arn   = var.cert_arn
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.polybot-tg.arn
  }
}

resource "aws_iam_role" "polybot-role" {
  name = "polybot-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"  
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_policy" "polybot-policy" {
  name        = "polybot-policy"
  description = "Policy to allow access to DynamoDB, S3, SQS, and Secrets Manager"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "dynamodb:PutItem",
          "dynamodb:GetItem",
          "dynamodb:Scan",
          "dynamodb:UpdateItem"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "s3:PutObject",
          "s3:GetObject",
          "s3:DeleteObject"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = "sqs:*"
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "attach_polybot-policy" {
  role       = aws_iam_role.polybot-role.name
  policy_arn = aws_iam_policy.polybot-policy.arn
}