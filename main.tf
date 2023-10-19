provider "aws" {
  region = "us-east-2"
}

variable "server_port" {
  description = "The port the server will use for HTTP requests"
  type = number
  default = 8080
}

output "public_ip" {
  value = aws_instance.example.public_ip
  description = "The public IP address of the web server"
}

resource "aws_launch_configuration" "example" {
  image_id = "ami-0fb653ca2d3203ac1"
  instance_type = "t3.micro"
  security_groups = [aws_security_group.instance.id ]

  user_data = <<-EOF
                #!/bin/bash
                echo "Hello, World" > index.xhtml
                nohup busybox httpd -f -p ${var.server_port} &
                EOF
  
  # To create instances before destroying the old ones, usefill for ASG
  lifecycle {
    create_before_destroy = true
  }
  
}

resource "aws_autoscaling_group" "example" {
  launch_configuration = aws_launch_configuration.example.name

  min_size = 2
  max_size = 10

  tag {
    key = "Name"
    value = "Terraform-asg-example"
    propagate_at_launch = true
  }
}

resource "aws_security_group" "instance" {
  name = "terraform-example-instance"

  ingress {
    from_port = var.server_port
    to_port = var.server_port
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
