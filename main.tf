# --------------------
# 🚀 VPC & Réseau
# --------------------

# Création du VPC
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

# Sous-réseaux privés
resource "aws_subnet" "private_subnet" {
  vpc_id            = aws_vpc.main_vpc.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "us-east-1c"
  map_public_ip_on_launch = false
  tags = { Name = "private-subnet" }
}

# --------------------
# 🌐 Internet Gateway & NAT Gateway
# --------------------

# Internet Gateway pour accès public
resource "aws_internet_gateway" "main_igw" {
  vpc_id = aws_vpc.main_vpc.id
  tags = { Name = "main-internet-gateway" }
}

# Elastic IPs
resource "aws_eip" "nat_eip" { domain = "vpc" }
resource "aws_eip" "eip_secondary" { domain = "vpc" }

# NAT Gateway pour accès privé
resource "aws_nat_gateway" "nat_gateway" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id     = aws_subnet.public_subnet_1.id
  tags = { Name = "nat-gateway" }
}

# --------------------
# 🛣️ Tables de Routage
# --------------------

# Table de routage publique
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.main_vpc.id
  tags = { Name = "public-route-table" }
}

# Route vers Internet via Internet Gateway
resource "aws_route" "public_route" {
  route_table_id         = aws_route_table.public_rt.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.main_igw.id
}

# Association de la table publique aux sous-réseaux publics
resource "aws_route_table_association" "public_subnet_1_association" {
  subnet_id      = aws_subnet.public_subnet_1.id
  route_table_id = aws_route_table.public_rt.id
}

resource "aws_route_table_association" "public_subnet_2_association" {
  subnet_id      = aws_subnet.public_subnet_2.id
  route_table_id = aws_route_table.public_rt.id
}

# Table de routage privée
resource "aws_route_table" "private_rt" {
  vpc_id = aws_vpc.main_vpc.id
  tags = { Name = "private-route-table" }
}

# Route vers Internet via NAT Gateway (sortie privée)
resource "aws_route" "private_route" {
  route_table_id         = aws_route_table.private_rt.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.nat_gateway.id
}

# Association de la table privée aux sous-réseaux privés
resource "aws_route_table_association" "private_subnet_association" {
  subnet_id      = aws_subnet.private_subnet.id
  route_table_id = aws_route_table.private_rt.id
}

# --------------------
# 🔒 Security Groups
# --------------------

# SG pour accès SSH interne uniquement
resource "aws_security_group" "ssh_access_sg" {
  name        = "ssh-access-sg"
  description = "Allow SSH access within VPC"
  vpc_id      = aws_vpc.main_vpc.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]  # Limite l'accès SSH au réseau interne
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "ssh-access-sg" }
}

# --------------------
# 🖥️ Instances EC2
# --------------------

# Utiliser une clé SSH existante
data "aws_key_pair" "vockey" { key_name = "vockey" }

# Instance EC2 publique (accès SSH autorisé) - Dans le premier sous-réseau
resource "aws_instance" "ec2_public_1" {
  ami           = "ami-0c02fb55956c7d316"
  instance_type = "t2.micro"
  key_name      = data.aws_key_pair.vockey.key_name
  subnet_id     = aws_subnet.public_subnet_1.id

  associate_public_ip_address = true

  vpc_security_group_ids = [aws_security_group.ssh_access_sg.id]

  tags = { Name = "ec2-public-1" }
}

# Instance EC2 publique (accès SSH autorisé) - Dans le deuxième sous-réseau
resource "aws_instance" "ec2_public_2" {
  ami           = "ami-0c02fb55956c7d316"
  instance_type = "t2.micro"
  key_name      = data.aws_key_pair.vockey.key_name
  subnet_id     = aws_subnet.public_subnet_2.id

  associate_public_ip_address = true

  vpc_security_group_ids = [aws_security_group.ssh_access_sg.id]

  tags = { Name = "ec2-public-2" }
}

# Instance EC2 privée (accès uniquement via SSH interne)
resource "aws_instance" "ec2_private" {
  ami           = "ami-0c02fb55956c7d316"
  instance_type = "t2.micro"
  key_name      = data.aws_key_pair.vockey.key_name
  subnet_id     = aws_subnet.private_subnet.id

  associate_public_ip_address = false

  vpc_security_group_ids = [aws_security_group.ssh_access_sg.id]

  tags = { Name = "ec2-private" }
}
