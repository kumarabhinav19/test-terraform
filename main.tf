

//create vpc 
resource "aws_vpc" "my_first_vpc" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "production-vpc"
  }
}



//create internet gateway
resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.my_first_vpc.id

  tags = {
    Name = "main"
  }
}

//create aws route table
resource "aws_route_table" "my_route_table" {
  vpc_id = aws_vpc.my_first_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }

  route {
    ipv6_cidr_block        = "::/0"
    gateway_id  = aws_internet_gateway.gw.id
  }

  tags = {
    Name = "route-table"
  }
}
// create subnet
resource "aws_subnet" "my_first_subnet" {
  vpc_id            = aws_vpc.my_first_vpc.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "us-east-1a"

  tags = {
    Name = "production-subnet"
  }
}

//create route table associate with subnet
resource "aws_route_table_association" "a" {
  subnet_id      = aws_subnet.my_first_subnet.id
  route_table_id = aws_route_table.my_route_table.id
}

//create security group
resource "aws_security_group" "allow_web" {
  name        = "allow_tls"
  description = "Allow TLS inbound traffic"
  vpc_id      = aws_vpc.my_first_vpc.id

  ingress {
    description = "https"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]

  }

  ingress {
    description = "http"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]

  }
  ingress {
    description = "ssh"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]

  }
  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "allow_ssh_http_https"
  }
}

//create network interface
resource "aws_network_interface" "test" {
  subnet_id       = aws_subnet.my_first_subnet.id
  private_ips     = ["10.0.1.50"]
  security_groups = [aws_security_group.allow_web.id]

}

//create elastic ip for nic
resource "aws_eip" "one" {
  vpc                       = true
  network_interface         = aws_network_interface.test.id
  associate_with_private_ip = "10.0.1.50"
  depends_on                = [aws_internet_gateway.gw]
}

//create aws server

resource "aws_instance" "web-server" {
  ami               = "ami-0742b4e673072066f"
  instance_type     = "t2.micro"
  availability_zone = "us-east-1a"
  network_interface {
    device_index         = 0
    network_interface_id = aws_network_interface.test.id
  }

  tags = {
    Name = "web-server"
  }
}
