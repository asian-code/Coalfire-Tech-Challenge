# for anything that is related to network security, VPC, subnets, security groups, route tables, internet gateways, etc.

resource "aws_vpc" "main" {
  cidr_block = var.vpc_cidr

  tags = {
    createdBy = "terraform"
    Name      = "main-vpc"
  }
}

# create the public subnets
resource "aws_subnet" "public" {
  for_each                = var.public_subnets
  map_public_ip_on_launch = true
  vpc_id                  = aws_vpc.main.id
  cidr_block              = each.value
  availability_zone       = data.aws_availability_zones.available.names[each.key == "subnet1" ? 0 : 1]

  tags = {
    createdBy = "terraform"
    Name      = "public-${each.key}"
  }
}
# create the private subnets
resource "aws_subnet" "private" {
  for_each = var.private_subnets

  vpc_id            = aws_vpc.main.id
  cidr_block        = each.value
  availability_zone = data.aws_availability_zones.available.names[each.key == "subnet3" ? 0 : 1]

  tags = {
    createdBy = "terraform"
    Name      = "private-${each.key}"
  }
}


resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id

  tags = {
    createdBy = "terraform"
    Name      = "main-tf-igw"
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }

  tags = {
    createdBy = "terraform"
    Name      = "public-rt"
  }
}

resource "aws_route_table_association" "public_association" { # loop through each public subnet and assign the route table
  for_each       = aws_subnet.public
  subnet_id      = each.value.id
  route_table_id = aws_route_table.public.id
}
resource "aws_route_table" "private" { # local route is added by default
  vpc_id = aws_vpc.main.id

  tags = {
    createdBy = "terraform"
    Name      = "private-rt"
  }
}

resource "aws_route_table_association" "private_association" { # loop through each private subnet and assign the route table
  for_each       = aws_subnet.private
  subnet_id      = each.value.id
  route_table_id = aws_route_table.private.id
}
resource "aws_security_group" "private_sg" {
  name        = "private-sg"
  description = "Allow HTTP traffic"
  vpc_id      = aws_vpc.main.id
  tags = {
    createdBy = "terraform"
    Name      = "private_sg"
  }
}
resource "aws_vpc_security_group_ingress_rule" "private_allow_https_alb" {
  security_group_id            = aws_security_group.private_sg.id
  referenced_security_group_id = aws_security_group.lb_sg.id
  from_port                    = 443
  ip_protocol                  = "tcp"
  to_port                      = 443
}
resource "aws_security_group" "lb_sg" {
  name        = "alb-sg"
  description = "Allow HTTP traffic and outbound HTTPS to private SG"
  vpc_id      = aws_vpc.main.id
  tags = {
    createdBy = "terraform"
    Name      = "alb_sg"
  }
}
# resource "aws_vpc_security_group_ingress_rule" "allow_https_in_lb" { #require ACM cert and HTTPS listner in lb
#   security_group_id = aws_security_group.lb_sg.id
#   cidr_ipv4         = "0.0.0.0/0"
#   from_port         = 443
#   ip_protocol       = "tcp"
#   to_port           = 443
# }
resource "aws_vpc_security_group_ingress_rule" "allow_http_in_lb" {
  security_group_id = aws_security_group.lb_sg.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 80
  ip_protocol       = "tcp"
  to_port           = 80
}
resource "aws_vpc_security_group_egress_rule" "allow_https_out_lb" {
  security_group_id            = aws_security_group.lb_sg.id
  referenced_security_group_id = aws_security_group.private_sg.id
  from_port                    = 443
  ip_protocol                  = "tcp"
  to_port                      = 443
}