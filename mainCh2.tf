#  Set up everything but the ELB first
#  (comment out ELB ref in the ASG)
#  Then uncomment and run ELB once EC2 mods are 2/2
#  issues with healthcheck are preventing the binding of the ELB


provider "aws" {
  region = "us-east-2"
}

data "aws_availability_zones" "all" {}


variable "server_port" {
  description = "The server port for HTTP requests."
  default = 8080
}

output "elb_dns_name" {
  value = "${aws_elb.example.dns_name}"
}


resource "aws_security_group" "instance" {
  name = "terraform-example-instance"

  ingress {
    from_port   = "${var.server_port}"
    to_port     = "${var.server_port}"
    protocol    = "tcp"
    cidr_blocks = ["96.230.53.15/32"]
  }
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group" "elb" {
    name = "terraform-example-elb"

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


resource "aws_launch_configuration" "example" {
    image_id        = "ami-5e8bb23b"
    instance_type   = "t2.micro"
    security_groups = ["${aws_security_group.instance.id}"]

    user_data = <<-EOF
                #!/bin/bash
                echo "Hello, TerraWorld!" >index.html
                nohup busybox httpd -f -p "${var.server_port}" &
                EOF
    lifecycle {
      create_before_destroy = true
    }
}

resource "aws_autoscaling_group" "example" {
    launch_configuration = "${aws_launch_configuration.example.id}"
    availability_zones = ["${data.aws_availability_zones.all.names}"]

    load_balancers    = ["${aws_elb.example.name}"]
    health_check_type = "ELB"

    min_size = 2
    max_size = 10

    tag {
      key                 = "Name"
      value               = "tereaform-asg-example"
      propagate_at_launch = true
    }
}

resource "aws_elb" "example" {
    name                = "terraform-asg-example"
    availability_zones  = ["${data.aws_availability_zones.all.names}"]
    security_groups     = ["${aws_security_group.elb.id}"]

    listener {
      instance_port     = "${var.server_port}"
      instance_protocol = "http"
      lb_port           = 80
      lb_protocol       = "http"
    }


    health_check {
      healthy_threshold   = 2
      unhealthy_threshold = 10
      timeout             = 3
      target              = "HTTP:${var.server_port}/"
      interval            = 30
    }
}

/*
# single server config - obs
resource "aws_instance" "example" {
  ami           = "ami-5e8bb23b"
  instance_type = "t2.micro"
  vpc_security_group_ids = ["${aws_security_group.instance.id}"]

  user_data = <<-EOF
              #!/bin/bash
              echo "Hello, TerraWorld!" >index.html
              nohup busybox httpd -f -p "${var.server_port}" &
              EOF

  tags {
    Name = "learn terraform ch2"
  }

}
*/
