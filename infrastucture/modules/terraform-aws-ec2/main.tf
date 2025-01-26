resource "tls_private_key" "generated_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "ec2_key" {
  key_name   = var.ec2_key
  public_key = tls_private_key.generated_key.public_key_openssh
}

resource "aws_vpc" "main_vpc" {
  cidr_block = var.main_vpc_cidr_block
  tags = {
    Name = var.vpc_name
  }
}

resource "aws_subnet" "public_subnet" {
  vpc_id                  = aws_vpc.main_vpc.id
  cidr_block              = var.public_subnet_cidr_block
  map_public_ip_on_launch = true
  availability_zone       = var.availability_zone
  tags = {
    Name = var.public_subnet_name
  }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main_vpc.id
  tags = {
    Name = var.igw_name
  }
}

resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.main_vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
  tags = {
    Name = var.route_table_name
  }
}

resource "aws_route_table_association" "public_association" {
  subnet_id      = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.public_rt.id
}

resource "aws_security_group" "activegate_sg" {
  name        = var.security_group_name
  description = var.security_group_description
  vpc_id      = aws_vpc.main_vpc.id

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "ActiveGate port"
    from_port   = 9999
    to_port     = 9999
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Allow all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = var.security_group_name
  }
}

data "aws_iam_role" "role_data" {
  count = var.role_name == "" ? 0 : 1
  name  = var.role_name
}

resource "aws_iam_instance_profile" "role_instance_profile" {
  count = var.role_name == "" ? 0 : 1
  name  = var.role_name == "" ? "" : "role_instance_profile"
  role  = var.role_name == "" ? null : data.aws_iam_role.role_data[0].name
}

resource "aws_instance" "instance" {
  ami                    = var.ami_id
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.public_subnet.id
  vpc_security_group_ids = [aws_security_group.activegate_sg.id]
  associate_public_ip_address = true
  key_name = aws_key_pair.ec2_key.key_name
  iam_instance_profile = var.role_name == "" ? null : aws_iam_instance_profile.role_instance_profile[0].name

  tags = {
    Name = var.instance_name
  }
}
