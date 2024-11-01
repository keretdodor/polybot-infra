#AMI creation
resource "aws_instance" "yolo5" {
  ami                    = data.aws_ami.ubuntu_ami.id
  instance_type         = var.instance_type
  key_name              = var.key_name
  subnet_id             = var.subnet_id[0]
  vpc_security_group_ids = [aws_security_group.yolo5-sg.id]
  associate_public_ip_address = true
  
  tags = {
    Name = "yolo5"
  }

  connection {
    type        = "ssh"
    user        = "ubuntu"
    private_key = var.private_key
    host        = self.public_ip
  }

  provisioner "remote-exec" {
    inline = [
      "sudo apt update -y",
      "sudo apt install -y docker.io",
      "sudo systemctl start docker",
      "sudo systemctl enable docker",
      "sudo docker pull keretdodor/yolo5",
      "sudo docker run -d --restart always -e AWS_REGION=${var.aws_region} -e DYNAMODB_TABLE=${var.dynamodb_table_name} -e S3_BUCKET=${var.s3_bucket} -e SQS_QUEUE_URL=${var.sqs_queue_url} -e ALIAS_RECORD=${var.alias_record} keretdodor/yolo5"
    ]
  }

  }

resource "aws_security_group" "yolo5-sg" {
  name        = "yolo5-sg"  
  description = "Allow SSH and HTTP traffic"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] 
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

resource "aws_ami_from_instance" "yolo5-ami" {
name               = "app-ami-yolo5"
source_instance_id = aws_instance.yolo5.id
description        = "ami from yolo5 instance"
}

resource "aws_launch_template" "yolo5-template" {
  name          = "yolo5-launch-template"
  image_id      = aws_ami_from_instance.yolo5-ami.id
  instance_type = var.instance_type
  iam_instance_profile {
    name = aws_iam_instance_profile.yolo5-instance-profile.name
  }
  network_interfaces {
    security_groups = [aws_security_group.yolo5-sg.id]
  }
}

resource "null_resource" "terminate_instance" {
  provisioner "local-exec" {
    command = "aws ec2 terminate-instances --instance-ids ${aws_instance.yolo5.id}"
  }

  depends_on = [aws_ami_from_instance.yolo5-ami]
}

#------------------------------------------------------------------------
# AWS Auto Scaling Group

resource "aws_placement_group" "yolo5-pg" {
  name     = "test"
  strategy = "spread"
}


resource "aws_autoscaling_group" "yolo5-asg" {
  launch_template {
    id      = aws_launch_template.yolo5-template.id
    version = "$Latest"  
  }
  name                      = "yolo5-asg"
  max_size                  = 6
  min_size                  = 2
  health_check_grace_period = 300
  health_check_type         = "ELB"
  desired_capacity          = 2
  force_delete              = true
  placement_group           = aws_placement_group.yolo5-pg.id
  vpc_zone_identifier       = var.subnet_id

  instance_maintenance_policy {
    min_healthy_percentage = 90
    max_healthy_percentage = 120

    
  }
}
resource "aws_cloudwatch_metric_alarm" "scale-out" {
  alarm_name          = "scale-out-alarm"
  alarm_description   = "Alarm when CPU exceeds 60%"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  statistic           = "Average"
  period              = 300
  evaluation_periods  = 1
  threshold           = 60
  comparison_operator = "GreaterThanThreshold"
  alarm_actions       = [aws_autoscaling_policy.scale-out.arn]
  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.yolo5-asg.name
  }
}

resource "aws_autoscaling_policy" "scale-out" {
  name                   = "scale-out-policy"
  scaling_adjustment      = 1
  adjustment_type        = "ChangeInCapacity"
  autoscaling_group_name = aws_autoscaling_group.yolo5-asg.name
}

resource "aws_cloudwatch_metric_alarm" "scale-in" {
  alarm_name          = "scale-in-alarm"
  alarm_description   = "Alarm when CPU is below 30%"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  statistic           = "Average"
  period              = 300
  evaluation_periods  = 1
  threshold           = 30
  comparison_operator = "LessThanThreshold"
  alarm_actions       = [aws_autoscaling_policy.scale-in.arn]
  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.yolo5-asg.name
  }
}

resource "aws_autoscaling_policy" "scale-in" {
  name                   = "scale-in-policy"
  scaling_adjustment      = -1
  adjustment_type        = "ChangeInCapacity"
  autoscaling_group_name = aws_autoscaling_group.yolo5-asg.name
}


#-----------------------------------------------------------------------------------
# IAM policy and IAM role being created

resource "aws_iam_role" "yolo5-role" {
  name = "yolo5-role"

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

resource "aws_iam_policy" "yolo5-policy" {
  name        = "yolo5-policy"
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

resource "aws_iam_role_policy_attachment" "attach_yolo5-policy" {
  role       = aws_iam_role.yolo5-role.name
  policy_arn = aws_iam_policy.yolo5-policy.arn
}
resource "aws_iam_instance_profile" "yolo5-instance-profile" {
  name = "yolo5-instance-profile"
  role = aws_iam_role.yolo5-role.name
}