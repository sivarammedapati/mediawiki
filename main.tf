# Configure the AWS Provider
provider "aws" {
  region  = "ap-south-1"
}
variable "ips" {
    default = {
        "0" = "10.0.1.35"
        "1" = "10.0.1.36"
    }
}
variable "web_instance_count" {
  default = "1"
}
variable "db_instance_count" {
  default = "0"
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
resource "aws_security_group" "elb_sg" {
  name        = "ELB SG"
  vpc_id      = "${aws_vpc.main.id}"
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
  egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
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
    cidr_blocks = ["0.0.0.0/0"]
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
    to_port         = 0
    protocol        = "-1"
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
resource "aws_key_pair" "deployer" {
  key_name   = "deployer-key"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC4U6jrIWgHoARLQnpxsd1hlD/NljB2PgTz61AOXXUjZV05a7xPWUp9G++uk0ASOZBU6d2EwlQDccd01vgRQLZZw0hzLJFWnurbeTLLSA8qil5Z+mXDJml/WRvgrE2M9uwhVDLmUW+UcAoQjaENiFDlNK36znN1wMdaQGWTZRlSQEeUumplxoxNn9qsieAgIvkokoV8NkGrpWAL/N640XEChGd7xZxv9qIhO4bNlHed4gjq69F4yc7XEZt5nqA8DfnBIzKn6XBb0u1NgDnueEG8sIOcI0bNvmMECddSVT/JeMdbxelidGvCAB6HZSFwXvHe4Pht6RPEMtgmw3uexiy7 email@example.com"
}
resource "aws_instance" "web_instance" {
  count         = "${var.web_instance_count}"
  ami           = "ami-02e60be79e78fef21"
  private_ip = "${lookup(var.ips,count.index)}"
  associate_public_ip_address = "true"
  instance_type = "t2.micro"
  vpc_security_group_ids = ["${aws_security_group.web_server_sg.id}"]
  key_name = "${aws_key_pair.deployer.key_name}"
  availability_zone = "ap-south-1a"
  subnet_id = "${aws_subnet.pubsub.id}"
  provisioner "file" {
    source      = "./key.pem"
    destination = "/home/centos/key.pem"
  connection {
    host = self.public_ip
    type     = "ssh"
    user     = "centos"
    private_key = "${file("./key.pem")}"
  }
  }
  provisioner "file" {
    source      = "./script.sh"
    destination = "/home/centos/script.sh"
  connection {
    host = self.public_ip
    type     = "ssh"
    user     = "centos"
    private_key = "${file("./key.pem")}"
  }
  }
   provisioner "file" {
    source      = "./LocalSettings.php"
    destination = "/home/centos/LocalSettings.php"
  connection {
    host = self.public_ip
    type     = "ssh"
    user     = "centos"
    private_key = "${file("./key.pem")}"
  }
  }
  provisioner "remote-exec" {
    inline = [
      "chmod 600 /home/centos/key.pem",
      "chmod +x /home/centos/script.sh",
      "sudo sh script.sh"
    ]
    connection {
    host = self.public_ip
    type     = "ssh"
    user     = "centos"
    private_key = "${file("./key.pem")}"
  }
  }
  tags = {
    Name = "Web Server ${count.index + 1}"
  }
}
/*
resource "aws_instance" "jump_instance" {
  ami           = "ami-02e60be79e78fef21"
  instance_type = "t2.micro"
  vpc_security_group_ids = ["${aws_security_group.jump_server_sg.id}"]
  key_name = "${aws_key_pair.deployer.key_name}"
  private_ip = "10.0.1.30"
  associate_public_ip_address = "true"
  availability_zone = "ap-south-1a"
  subnet_id = "${aws_subnet.pubsub.id}"
  provisioner "file" {
    source      = "./key.pem"
    destination = "/home/centos/key.pem"
  connection {
    host = self.public_ip    
    type     = "ssh"
    user     = "centos"
    private_key = "${file("./key.pem")}"
  }
  }
  provisioner "file" {
    source      = "./script.sh"
    destination = "/home/centos/script.sh"
  connection {
    host = self.public_ip
    type     = "ssh"
    user     = "centos"
    private_key = "${file("./key.pem")}"
  }
  }
   provisioner "file" {
    source      = "./LocalSettings.php"
    destination = "/home/centos/LocalSettings.php"
  connection {
    host = self.public_ip
    type     = "ssh"
    user     = "centos"
    private_key = "${file("./key.pem")}"
  }
  }
  provisioner "remote-exec" {
    inline = [
      "chmod 600 /home/centos/key.pem",
      "scp -i /home/centos/key.pem /home/centos/script.sh centos@10.0.1.35:~"
    ]
    connection {
    host = self.public_ip
    type     = "ssh"
    user     = "centos"
    private_key = "${file("./key.pem")}"
  }
  }
  tags = {
    Name = "Jump Host"
  }
}
*/
resource "aws_instance" "db_instance" {
  count         = "${var.db_instance_count}"
  ami           = "ami-02e60be79e78fef21"
  instance_type = "t2.micro"
  vpc_security_group_ids = ["${aws_security_group.db_server_sg.id}"]
  key_name = "${aws_key_pair.deployer.key_name}"  
  availability_zone = "ap-south-1a"
  subnet_id = "${aws_subnet.prisub.id}"
  tags = {
    Name = "DB Server ${count.index + 1}"
  }
}
resource "aws_elb" "web_elb" {
  name = "WebServerELB"
  subnets = ["${aws_subnet.pubsub.id}"]
  security_groups = ["${aws_security_group.elb_sg.id}"]
  listener {
    instance_port     = 80
    instance_protocol = "http"
    lb_port           = 80
    lb_protocol       = "http"
  }
  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 3
    target              = "HTTP:80/"
    interval            = 30
  }
# instances                   = ["${aws_instance.web_instance[0].id}","${aws_instance.web_instance[1].id}"]
  instances                   = ["${aws_instance.web_instance[0].id}"]
  cross_zone_load_balancing   = true
  idle_timeout                = 400
  connection_draining         = true
  connection_draining_timeout = 400

  tags = {
    Name = "Web Server ELB"
  }
}
