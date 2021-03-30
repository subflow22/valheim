data "aws_caller_identity" "current" {}

resource "aws_vpc" "default" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = merge(
    var.tags,
    {
      "Name" = var.namespace
    }
  )
}

resource "aws_subnet" "public" {
  count                   = length(var.pubnets) > length(var.az_names) ? length(var.az_names) : length(var.pubnets)
  vpc_id                  = aws_vpc.default.id
  cidr_block              = var.pubnets[count.index]
  availability_zone       = var.az_names[count.index]
  map_public_ip_on_launch = true

  tags = merge(
    var.tags,
    {
      "Name"        = "${var.namespace}-public-${count.index}",
      "subnet:type" = "public"
    }
  )
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.default.id
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.default.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = merge(
    var.tags,
    {
      "Name" = "${var.namespace}-public"
    }
  )
}

resource "aws_route_table_association" "public" {
  count          = length(var.pubnets) > length(var.az_names) ? length(var.az_names) : length(var.pubnets)
  subnet_id      = element(aws_subnet.public.*.id, count.index)
  route_table_id = aws_route_table.public.id
}

data "aws_subnet_ids" "ids" {

  depends_on = [
    aws_subnet.public
  ]

  vpc_id = aws_vpc.default.id
}

resource "aws_cloudwatch_log_group" "default" {
  name              = "/aws/${var.namespace}/logs"
  retention_in_days = 3
}

resource "aws_route53_record" "default" {

  depends_on = [
    aws_instance.default
  ]

  zone_id = var.zone
  name    = "${var.namespace}.${var.domain}"
  type    = "A"
  ttl     = "300"
  records = [aws_instance.default.public_ip]
}

