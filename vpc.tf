resource "aws_vpc" "titus" {
  cidr_block           = "30.0.0.0/16"
  enable_dns_support   = "true"
  enable_dns_hostnames = "true"
}

resource "aws_subnet" "private_subnet_1" {
  vpc_id     = "${aws_vpc.titus.id}"
  cidr_block = "30.0.100.0/24"
}

resource "aws_subnet" "public_subnet_1" {
  vpc_id     = "${aws_vpc.titus.id}"
  cidr_block = "30.0.1.0/24"
}

resource "aws_internet_gateway" "internet_gw" {
  vpc_id = "${aws_vpc.titus.id}"
}

resource "aws_route_table" "public_route_table" {
  vpc_id = "${aws_vpc.titus.id}"

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.internet_gw.id}"
  }
}

resource "aws_main_route_table_association" "vpc_route_table" {
  vpc_id         = "${aws_vpc.titus.id}"
  route_table_id = "${aws_route_table.public_route_table.id}"
}

resource "aws_eip" "nat" {
  vpc = true
}

resource "aws_nat_gateway" "nat" {
  allocation_id = "${aws_eip.nat.id}"
  subnet_id     = "${aws_subnet.public_subnet_1.id}"
}

resource "aws_route_table" "private_route_table" {
  vpc_id = "${aws_vpc.titus.id}"

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = "${aws_nat_gateway.nat.id}"
  }
}

resource "aws_route_table_association" "private_route_table" {
  subnet_id      = "${aws_subnet.private_subnet_1.id}"
  route_table_id = "${aws_route_table.private_route_table.id}"
}
