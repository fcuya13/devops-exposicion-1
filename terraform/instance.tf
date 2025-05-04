resource "aws_key_pair" "deployer" {
  key_name   = var.ec2_key_name
  public_key = file("../keys/devops-key.pub")
}

# Security group for web servers
resource "aws_security_group" "network-security-group" {
  name        = var.network-security-group-name
  description = "Allow TLS inbound traffic and HTTP"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "SSH from Ansible Control Node"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["${aws_instance.ansible_control.private_ip}/32"]
  }

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
    Name = "web-servers-sg"
  }
}

# Security group for Ansible control node
resource "aws_security_group" "ansible_control" {
  name        = "ansible-control-sg"
  description = "Security group for Ansible control node"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "SSH from your IP"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # In production, restrict this to your IP
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "ansible-control-sg"
  }
}

# Security group for Application Load Balancer
resource "aws_security_group" "alb" {
  name        = "alb-security-group"
  description = "Security group for Application Load Balancer"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "HTTP from anywhere"
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
    Name = "alb-sg"
  }
}

# Ansible control instance in public subnet
resource "aws_instance" "ansible_control" {
  ami           = var.ubuntu-ami
  instance_type = "t2.micro"
  subnet_id     = aws_subnet.public[0].id
  key_name      = aws_key_pair.deployer.key_name
  vpc_security_group_ids = [aws_security_group.ansible_control.id]
  associate_public_ip_address = true

  user_data = <<-EOF
              #!/bin/bash
              apt-get update
              apt-get install -y ansible
              mkdir -p /etc/ansible
              echo "[web_servers]" > /etc/ansible/hosts
              EOF

  tags = {
    Name = "ansible-control"
  }
}

# Web server instances in private subnets
resource "aws_instance" "ubuntu-vm-instance" {
  count                  = 2
  ami                    = var.ubuntu-ami
  instance_type          = var.ec2_instance_type
  subnet_id              = aws_subnet.private[count.index].id
  key_name              = aws_key_pair.deployer.key_name
  vpc_security_group_ids = [aws_security_group.network-security-group.id]
  
  tags = {
    Name = "ubuntu-vm-${count.index + 1}"
  }

  depends_on = [aws_instance.ansible_control]
}

# Application Load Balancer
resource "aws_lb" "app_lb" {
  name               = "application-load-balancer"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets           = aws_subnet.public[*].id

  tags = {
    Name = "app-load-balancer"
  }
}

# Target Group for ALB
resource "aws_lb_target_group" "app_tg" {
  name     = "app-target-group"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id

  health_check {
    enabled             = true
    healthy_threshold   = 2
    interval            = 30
    matcher            = "200"
    path               = "/"
    port               = "traffic-port"
    protocol           = "HTTP"
    timeout            = 5
    unhealthy_threshold = 2
  }
}

# ALB Listener
resource "aws_lb_listener" "front_end" {
  load_balancer_arn = aws_lb.app_lb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app_tg.arn
  }
}

# Target Group Attachments
resource "aws_lb_target_group_attachment" "app_tg_attachment" {
  count            = 2
  target_group_arn = aws_lb_target_group.app_tg.arn
  target_id        = aws_instance.ubuntu-vm-instance[count.index].id
  port             = 80
}