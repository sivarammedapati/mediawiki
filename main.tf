# Configure the AWS Provider
provider "aws" {
  region  = "ap-south-1"
}

variable "web_instance_count" {
  default = "2"
}
variable "db_instance_count" {
  default = "1"
}
# Create a VPC
resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
tags = {
    Name = "MediaWiki"
  }
}
resource "aws_subnet" "pubsub" {
  vpc_id     = "${aws_vpc.main.id}"
  cidr_block = "10.0.1.0/24"
  availability_zone = "ap-south-1a"
  tags = {
    Name = "Web Subnet"
  }
}
resource "aws_subnet" "prisub" {
  vpc_id     = "${aws_vpc.main.id}"
  cidr_block = "10.0.2.0/24"
  availability_zone = "ap-south-1a"
  tags = {
    Name = "DB Subnet"
  }
}
resource "aws_internet_gateway" "gw" {
  vpc_id = "${aws_vpc.main.id}"

  tags = {
    Name = "Internet Gateway"
  }
}
resource "aws_eip" "nat_eip" {
  vpc      = true
}
resource "aws_nat_gateway" "natgw" {
  allocation_id = "${aws_eip.nat_eip.id}"
  subnet_id     = "${aws_subnet.pubsub.id}"

  tags = {
    Name = "NAT Gateway"
  }
}
resource "aws_route_table" "pubrt" {
  vpc_id = "${aws_vpc.main.id}"

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.gw.id}"
  }
  tags = {
    Name = "Public Subnet Route"
  }
}
resource "aws_route_table" "prirt" {
  vpc_id = "${aws_vpc.main.id}"

  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = "${aws_nat_gateway.natgw.id}"
  }
  tags = {
    Name = "Private Subnet Route"
  }
}
resource "aws_route_table_association" "pub_rt_sub" {
  subnet_id      = "${aws_subnet.pubsub.id}"
  route_table_id = "${aws_route_table.pubrt.id}"
}
resource "aws_route_table_association" "pri_rt_sub" {
  subnet_id      = "${aws_subnet.prisub.id}"
  route_table_id = "${aws_route_table.prirt.id}"
}
resource "aws_security_group" "jump_server_sg" {
  name        = "Jump Server SG"
  vpc_id      = "${aws_vpc.main.id}"
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port       = 0
    to_port         = 65535
    protocol        = "tcp"
    cidr_blocks     = ["0.0.0.0/0"]
  }
}
resource "aws_security_group" "web_server_sg" {
  name        = "Web Server SG"
  vpc_id      = "${aws_vpc.main.id}"
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
  }
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port       = 0
    to_port         = 65535
    protocol        = "tcp"
    cidr_blocks     = ["0.0.0.0/0"]
  }
}
resource "aws_security_group" "db_server_sg" {
  name        = "DB Server SG"
  vpc_id      = "${aws_vpc.main.id}"
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
  }
  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
  }
  egress {
    from_port       = 0
    to_port         = 65535
    protocol        = "tcp"
    cidr_blocks     = ["0.0.0.0/0"]
  }
}
resource "aws_instance" "jump_instance" {
  ami           = "ami-02e60be79e78fef21"
  instance_type = "t2.micro"
  vpc_security_group_ids = ["${aws_security_group.jump_server_sg.id}"]
  key_name = "clikey"
  associate_public_ip_address = "true"
  availability_zone = "ap-south-1a"
  subnet_id = "${aws_subnet.pubsub.id}"
  tags = {
    Name = "Jump Host"
  }
}
resource "aws_instance" "web_instance" {
  count         = "${var.web_instance_count}"
  ami           = "ami-02e60be79e78fef21"
  instance_type = "t2.micro"
  vpc_security_group_ids = ["${aws_security_group.web_server_sg.id}"]
  key_name = "clikey"
  availability_zone = "ap-south-1a"
  subnet_id = "${aws_subnet.pubsub.id}"
  tags = {
    Name = "Web Server ${count.index + 1}"
  }
}
resource "aws_instance" "db_instance" {
  count         = "${var.db_instance_count}"
  ami           = "ami-02e60be79e78fef21"
  instance_type = "t2.micro"
  vpc_security_group_ids = ["${aws_security_group.db_server_sg.id}"]
  key_name = "clikey"
  availability_zone = "ap-south-1a"
  subnet_id = "${aws_subnet.prisub.id}"
  tags = {
    Name = "DB Server ${count.index + 1}"
  }
}
