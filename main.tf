provider "aws" {
  region = "us-east-2"
}

resource "aws_security_group" "instance" {
  name = "terraform-example-instance"
  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["96.230.53.15/32"]
  }
}
resource "aws_instance" "example" {
  ami           = "ami-5e8bb23b"
  instance_type = "t2.micro"
  vpc_security_group_ids = ["${aws_security_group.instance.id}"]

  user_data = <<-EOF
              #!/bin/bash
              echo "Hello, TerraWorld!" >index.html
              nohup busybox httpd -f -p 8080 &
              EOF

  tags {
    Name = "learn terraform ch2"
  }

}
