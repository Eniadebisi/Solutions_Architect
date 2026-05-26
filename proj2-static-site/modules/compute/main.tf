# Fetch latest Amazon Linux 2 AMI — avoids hardcoding region-specific AMI IDs
data "aws_ami" "amazon_linux_2" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# ── Public EC2 (web server) ────────────────────────────────────────────────────

resource "aws_instance" "public" {
  ami                    = data.aws_ami.amazon_linux_2.id
  instance_type          = var.instance_type
  subnet_id              = var.public_subnet_id
  vpc_security_group_ids = [var.public_sg_id]
  key_name               = var.key_name

  # Install Apache and serve a simple page confirming EC2 is live
  user_data = <<-EOF
    #!/bin/bash
    yum update -y
    yum install -y httpd
    systemctl start httpd
    systemctl enable httpd
    echo "<h1>EC2 Web Server - ${var.project_name}</h1><p>Instance ID: $(curl -s http://169.254.169.254/latest/meta-data/instance-id)</p>" > /var/www/html/index.html
  EOF

  # Required for CloudWatch detailed monitoring (free tier: basic is free, detailed costs)
  monitoring = false

  tags = { Name = "${var.project_name}-public-ec2" }
}

# ── Private EC2 (demonstrates subnet isolation) ────────────────────────────────

resource "aws_instance" "private" {
  ami                    = data.aws_ami.amazon_linux_2.id
  instance_type          = var.instance_type
  subnet_id              = var.private_subnet_id
  vpc_security_group_ids = [var.private_sg_id]
  key_name               = var.key_name

  # No user_data needed — this instance just demonstrates network isolation
  monitoring = false

  tags = { Name = "${var.project_name}-private-ec2" }
}
