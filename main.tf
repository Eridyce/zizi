# 🌐 VPC & Réseau
# ----------------------------

resource "aws_vpc" "main_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = { Name = "my-vpc" }
}

# Sous-réseaux publics
resource "aws_subnet" "public_subnet_1" {
  vpc_id                  = aws_vpc.main_vpc.id
  cidr_block              = "10.0.3.0/24"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true
  tags = { Name = "public-subnet-1" }
}

resource "aws_subnet" "public_subnet_2" {
  vpc_id                  = aws_vpc.main_vpc.id
  cidr_block              = "10.0.4.0/24"
  availability_zone       = "us-east-1b"
  map_public_ip_on_launch = true
  tags = { Name = "public-subnet-2" }
}

# Sous-réseau privé
resource "aws_subnet" "private_subnet" {
  vpc_id            = aws_vpc.main_vpc.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "us-east-1c"
  map_public_ip_on_launch = false
  tags = { Name = "private-subnet" }
}

# ----------------------------
# 🚀 Internet Gateway & NAT Gateway
# ----------------------------

resource "aws_internet_gateway" "main_igw" {
  vpc_id = aws_vpc.main_vpc.id
  tags = { Name = "main-internet-gateway" }
}

resource "aws_eip" "nat_eip" { domain = "vpc" }
resource "aws_eip" "eip_secondary" { domain = "vpc" }

resource "aws_nat_gateway" "nat_gateway" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id     = aws_subnet.public_subnet_1.id
  tags = { Name = "nat-gateway" }
}

# ----------------------------
# 🌐 Load Balancer (ALB) avec conditions simples
# ----------------------------

resource "aws_lb" "app_lb" {
  name               = "my-app-load-balancer"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.lb_sg.id]
  subnets            = [
    aws_subnet.public_subnet_1.id,
    aws_subnet.public_subnet_2.id
  ]
  enable_deletion_protection = false
  tags = { Name = "my-app-load-balancer" }
}

# ----------------------------
# 🎯 Groupes Cibles
# ----------------------------

resource "aws_lb_target_group" "target_group_app1" {
  name        = "target-group-app1"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = aws_vpc.main_vpc.id

  health_check {
    path                = "/health"
    protocol            = "HTTP"
  }

  tags = { Name = "target-group-app1" }
}

resource "aws_lb_target_group" "target_group_app2" {
  name        = "target-group-app2"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = aws_vpc.main_vpc.id

  health_check {
    path                = "/health"
    protocol            = "HTTP"
  }

  tags = { Name = "target-group-app2" }
}

resource "aws_lb_target_group" "target_group_default" {
  name        = "target-group-default"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = aws_vpc.main_vpc.id

  health_check {
    path                = "/"
    protocol            = "HTTP"
  }

  tags = { Name = "target-group-default" }
}

# ----------------------------
# 📜 Listeners avec Conditions Simples
# ----------------------------

resource "aws_lb_listener" "app_lb_listener" {
  load_balancer_arn = aws_lb.app_lb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = "forward"
    target_group_arn = aws_lb_target_group.target_group_default.arn
  }
}

# Règle conditionnelle pour /app1
resource "aws_lb_listener_rule" "rule_app1" {
  listener_arn = aws_lb_listener.app_lb_listener.arn
  priority     = 10

  condition {
    path_pattern {
      values = ["/app1/*"]
    }
  }

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.target_group_app1.arn
  }
}

# Règle conditionnelle pour /app2
resource "aws_lb_listener_rule" "rule_app2" {
  listener_arn = aws_lb_listener.app_lb_listener.arn
  priority     = 20

  condition {
    path_pattern {
      values = ["/app2/*"]
    }
  }

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.target_group_app2.arn
  }
}

# ----------------------------
# 🔒 Security Group pour Load Balancer
# ----------------------------

resource "aws_security_group" "lb_sg" {
  name        = "lb-security-group"
  description = "Security group for ALB"
  vpc_id      = aws_vpc.main_vpc.id

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

  tags = { Name = "lb-security-group" }
}