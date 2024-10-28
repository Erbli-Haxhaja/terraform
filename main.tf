# Configure the AWS Provider
provider "aws" {
  region = "us-east-1"
}

# Create a VPC with the network 10.1.0.0/16
resource "aws_vpc" "custom_vpc" {
  cidr_block = "10.1.0.0/16"
}

# Create an Internet Gateway
resource "aws_internet_gateway" "custom_igw" {
  vpc_id = aws_vpc.custom_vpc.id
}

# Create a Custom Route Table
resource "aws_route_table" "custom_route_table" {
  vpc_id = aws_vpc.custom_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.custom_igw.id
  }
}

# Create Subnet 1 in AZ a
resource "aws_subnet" "custom_subnet_1" {
  vpc_id                  = aws_vpc.custom_vpc.id
  cidr_block              = "10.1.10.0/24"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = false  # No public IPs for instances behind the ALB
}

# Create Subnet 2 in AZ b
resource "aws_subnet" "custom_subnet_2" {
  vpc_id                  = aws_vpc.custom_vpc.id
  cidr_block              = "10.1.11.0/24"
  availability_zone       = "us-east-1b"
  map_public_ip_on_launch = false  # No public IPs for instances behind the ALB
}

# Associate the Subnets with the Route Table
resource "aws_route_table_association" "custom_route_table_assoc_1" {
  subnet_id      = aws_subnet.custom_subnet_1.id
  route_table_id = aws_route_table.custom_route_table.id
}

resource "aws_route_table_association" "custom_route_table_assoc_2" {
  subnet_id      = aws_subnet.custom_subnet_2.id
  route_table_id = aws_route_table.custom_route_table.id
}

# Create a Security Group for the instances and ALB
resource "aws_security_group" "custom_web_sg" {
  name        = "custom_web_sg"
  description = "Allow HTTP inbound traffic and all outbound traffic"
  vpc_id      = aws_vpc.custom_vpc.id

  # Inbound rule for HTTP (port 80) traffic from ALB
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Outbound rule to allow all traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Create a Load Balancer with two subnets in different AZs
resource "aws_lb" "custom_lb" {
  name               = "custom-lb"
  internal           = false
  load_balancer_type = "application"
  subnets            = [aws_subnet.custom_subnet_1.id, aws_subnet.custom_subnet_2.id]
  security_groups    = [aws_security_group.custom_web_sg.id]
}

# Create an HTTP Listener for the Application Load Balancer
resource "aws_lb_listener" "custom_lb_listener" {
  load_balancer_arn = aws_lb.custom_lb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.custom_lb_tg.arn
  }
}

# Create a Target Group for the Load Balancer
resource "aws_lb_target_group" "custom_lb_tg" {
  name     = "custom-lb-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.custom_vpc.id
}

# Attach EC2 Instances to Target Group
resource "aws_lb_target_group_attachment" "custom_tg_attachment1" {
  target_group_arn = aws_lb_target_group.custom_lb_tg.arn
  target_id        = aws_instance.custom_web_instance1.id
  port             = 80
}

resource "aws_lb_target_group_attachment" "custom_tg_attachment2" {
  target_group_arn = aws_lb_target_group.custom_lb_tg.arn
  target_id        = aws_instance.custom_web_instance2.id
  port             = 80
}

# Launch the First EC2 Instance without Public IP in Subnet 1
resource "aws_instance" "custom_web_instance1" {
  ami                    = "ami-0866a3c8686eaeeba"
  instance_type          = "t2.micro"
  subnet_id              = aws_subnet.custom_subnet_1.id
  associate_public_ip_address = false  # No public IP for instances behind the ALB
  security_groups        = [aws_security_group.custom_web_sg.id]
  key_name               = "ec2-key"

  user_data = <<-EOF
    #!/bin/bash
    sudo apt-get update
    sudo apt-get install -y apache2
    sudo systemctl start apache2
    sudo systemctl enable apache2
    echo "<h1>Hello World from Instance 1</h1>" | sudo tee /var/www/html/index.html
  EOF

  tags = {
    Name = "custom_terraform_web_instance1"
  }
}

# Launch the Second EC2 Instance without Public IP in Subnet 2
resource "aws_instance" "custom_web_instance2" {
  ami                    = "ami-0866a3c8686eaeeba"
  instance_type          = "t2.micro"
  subnet_id              = aws_subnet.custom_subnet_2.id
  associate_public_ip_address = false  # No public IP for instances behind the ALB
  security_groups        = [aws_security_group.custom_web_sg.id]
  key_name               = "ec2-key"

  user_data = <<-EOF
    #!/bin/bash
    sudo apt-get update
    sudo apt-get install -y apache2
    sudo systemctl start apache2
    sudo systemctl enable apache2
    echo "<h1>Hello World from Instance 2</h1>" | sudo tee /var/www/html/index.html
  EOF

  tags = {
    Name = "custom_terraform_web_instance2"
  }
}

# Output the DNS name of the Load Balancer
output "custom_load_balancer_dns" {
  description = "The DNS name of the Load Balancer"
  value       = aws_lb.custom_lb.dns_name
}
