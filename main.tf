provider "aws" {
  region = "us-east-1"
}

resource "aws_vpc" "xops_vpc" {
  cidr_block = "10.0.0.0/16"
}

resource "aws_subnet" "xops_subnet" {
  vpc_id            = aws_vpc.xops_vpc.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "us-east-1a"
}

resource "aws_internet_gateway" "xops_igw" {
  vpc_id = aws_vpc.xops_vpc.id
}

resource "aws_route_table" "xops_route_table" {
  vpc_id = aws_vpc.xops_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.xops_igw.id
  }
}

resource "aws_route_table_association" "xops_assoc" {
  subnet_id      = aws_subnet.xops_subnet.id
  route_table_id = aws_route_table.xops_route_table.id
}

resource "aws_security_group" "xops_sg" {
  name        = "xops-web-sg"
  description = "Allow HTTP and SSH"
  vpc_id      = aws_vpc.xops_vpc.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 22
    to_port     = 22
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

resource "aws_instance" "xops_web" {
  ami                    = "ami-0c02fb55956c7d316"  # Amazon Linux 2 in us-east-1
  instance_type          = "t2.micro"
  subnet_id              = aws_subnet.xops_subnet.id
  vpc_security_group_ids = [aws_security_group.xops_sg.id]
  associate_public_ip_address = true

  user_data = <<-EOF
  #!/bin/bash
  yum update -y
  yum install -y httpd
  mkdir -p /var/www/html
  cat <<EOT > /var/www/html/index.html
  <!DOCTYPE html>
  <html lang="en">
  <head>
      <meta charset="UTF-8">
      <title>Hello from XOps</title>
      <style>
          body {
              background-image: url('https://cdn.pixabay.com/photo/2017/03/27/14/56/car-2179320_1280.jpg');
              background-size: cover;
              background-repeat: no-repeat;
              background-position: center;
              height: 100vh;
              display: flex;
              justify-content: center;
              align-items: center;
              font-family: Arial, sans-serif;
              color: white;
              text-shadow: 2px 2px 4px rgba(0,0,0,0.8);
          }
          h1 {
              font-size: 4em;
              background-color: rgba(0, 0, 0, 0.5);
              padding: 20px;
              border-radius: 10px;
          }
      </style>
  </head>
  <body>
      <h1>Hello from XOps 🚀</h1>
  </body>
  </html>
  EOT
  systemctl start httpd
  systemctl enable httpd
EOF

  tags = {
    Name = "xops-web"
  }
}