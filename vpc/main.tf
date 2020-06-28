terraform {
  required_version = ">= 0.10.3" # introduction of Local Values configuration language feature
}

locals {
  vpc_id             = aws_vpc.this.id
  max_subnet_length  = length(var.private_subnets)
  nat_gateway_count  = var.single_nat_gateway ? 1 : (var.one_nat_gateway_per_az ? length(var.azs) : local.max_subnet_length)
  nat_instance_count = var.single_nat_instance ? 1 : (var.one_nat_instance_per_az ? length(var.azs) : local.max_subnet_length)

  nat_count = var.enable_nat_instance ? local.nat_instance_count : local.nat_gateway_count
}

######
# VPC
######
resource "aws_vpc" "this" {
  cidr_block = var.cidr

  tags = "${merge(map("Name", format("%s", var.vpc_name)), var.tags, var.vpc_tags)}"
}

###################
# Internet Gateway
###################
resource "aws_internet_gateway" "this" {
  count = "${length(var.public_subnets) > 0 ? 1 : 0}"

  vpc_id = local.vpc_id

  tags = "${merge(map("Name", format("%s", var.vpc_name)), var.tags)}"
}

################
# Publiс routes
################
resource "aws_route_table" "public" {
  count = "${var.one_public_route_table_per_az ? length(var.public_subnets) : 1}"

  vpc_id = local.vpc_id

  tags = "${merge(map("Name", format("%s", var.vpc_name)), var.tags)}"
}

resource "aws_route" "public_internet_gateway" {
  count = var.one_public_route_table_per_az ? length(var.public_subnets) : 1

  route_table_id         = "${var.one_public_route_table_per_az ? element(aws_route_table.public.*.id, count.index) : element(aws_route_table.public.*.id, 0)}"
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.this[0].id

  timeouts {
    create = "5m"
  }
}

###################
# Public Subnet
###################
resource "aws_subnet" "public" {
  count             = "${length(var.public_subnets)}"
  vpc_id            = local.vpc_id
  cidr_block        = "${element(concat(var.public_subnets, list("")), count.index)}"
  availability_zone = "${element(var.azs, count.index)}"
  tags              = "${merge(map("Name", format("%s-${var.public_subnet_suffix}-%s", var.vpc_name, element(var.azs, count.index))), var.tags)}"
}

#################
# Private subnet
#################
resource "aws_subnet" "private" {
  count = "${length(var.private_subnets)}"

  vpc_id            = local.vpc_id
  cidr_block        = var.private_subnets[count.index]
  availability_zone = element(var.azs, count.index)

  tags = "${merge(map("Name", format("%s-${var.private_subnet_suffix}-%s", var.vpc_name, element(var.azs, count.index))), var.tags)}"
}

#################
# Private routes
# There are so many routing tables as the largest amount of subnets of each type (really?)
#################
resource "aws_route_table" "private" {
  count  = local.nat_count
  vpc_id = local.vpc_id

  tags = "${merge(map("Name", (format("%s-${var.private_subnet_suffix}-%s", var.vpc_name, element(var.azs, count.index)))), var.tags)}"

  lifecycle {
    # When attaching VPN gateways it is common to define aws_vpn_gateway_route_propagation
    # resources that manipulate the attributes of the routing table (typically for the private subnets)
    ignore_changes = ["propagating_vgws"]
  }
}

##########################
# Route table association
##########################
resource "aws_route_table_association" "public" {
  count = "${length(var.public_subnets)}"

  subnet_id      = "${element(aws_subnet.public.*.id, count.index)}"
  route_table_id = "${!var.one_public_route_table_per_az ? element(aws_route_table.public.*.id, 0) : element(aws_route_table.public.*.id, count.index)}"
}

resource "aws_route_table_association" "private" {
  count = "${length(var.private_subnets)}"

  subnet_id      = "${element(aws_subnet.private.*.id, count.index)}"
  route_table_id = "${element(aws_route_table.private.*.id, (var.single_nat_gateway ? 0 : count.index))}"
}

##############
# NAT Gateway
##############
# Workaround for interpolation not being able to "short-circuit" the evaluation of the conditional branch that doesn't end up being used
# Source: https://github.com/hashicorp/terraform/issues/11566#issuecomment-289417805
#
# The logical expression would be
#
#    nat_gateway_ips = var.reuse_nat_ips ? var.external_nat_ip_ids : aws_eip.nat.*.id
#
# but then when count of aws_eip.nat.*.id is zero, this would throw a resource not found error on aws_eip.nat.*.id.
locals {
  nat_ips = var.reuse_nat_ips ? "${var.external_nat_ip_ids}" : "${aws_eip.nat.*.id}"
  # nat_ips = "${split(",", (var.reuse_nat_ips ? join(",", var.external_nat_ip_ids) : join(",", aws_eip.nat.*.id)))}"
}

resource "aws_eip" "nat" {
  count = "${!var.reuse_nat_ips ? local.nat_count : 0}"
  vpc   = true

  tags = "${merge(map("Name", format("%s-%s", var.vpc_name, element(var.azs, ((var.single_nat_gateway || var.single_nat_instance) ? 0 : count.index)))), var.tags)}"

  # depends_on = "${var.enable_nat_instance && (local.nat_instance_count > 0) ? aws_instance.nat : [""]}"
}

resource "aws_nat_gateway" "this" {
  count = "${var.enable_nat_gateway ? local.nat_gateway_count : 0}"

  allocation_id = local.nat_ips[var.single_nat_gateway ? 0 : count.index]
  subnet_id     = "${element(aws_subnet.public.*.id, (var.single_nat_gateway ? 0 : count.index))}"

  tags = "${merge(map("Name", format("%s-%s", var.vpc_name, element(var.azs, (var.single_nat_gateway ? 0 : count.index)))), var.tags)}"

  depends_on = [aws_internet_gateway.this]
}

resource "aws_route" "private_nat_gateway" {
  count = "${var.enable_nat_gateway ? local.nat_gateway_count : 0}"

  route_table_id         = "${element(aws_route_table.private.*.id, count.index)}"
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = "${element(aws_nat_gateway.this.*.id, count.index)}"

  timeouts {
    create = "5m"
  }
}

###############
# NAT Instance 
###############
resource "aws_security_group" "nat" {
  count = var.enable_nat_instance ? local.nat_instance_count : 0

  name        = "${format("%s-sg-%s", var.vpc_name, element(var.azs, (var.single_nat_gateway ? 0 : count.index)))}"
  description = "Allow traffic to pass from the private subnet to the internet"

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = var.private_subnets
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = var.private_subnets
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = -1
    to_port     = -1
    protocol    = "icmp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = "${var.private_subnets}"
  }

  egress {
    from_port   = -1
    to_port     = -1
    protocol    = "icmp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  vpc_id = "${local.vpc_id}"

  tags = "${merge(map("Name", format("%s-sg-%s", var.vpc_name, element(var.azs, (var.single_nat_instance ? 0 : count.index)))), var.tags)}"
}

resource "aws_instance" "nat" {
  ami                         = "${var.nat_instance_ami_id}"                                                     # this is a special ami preconfigured to do NAT
  count                       = "${var.enable_nat_instance ? local.nat_instance_count : 0}"
  availability_zone           = "${element(var.azs, count.index)}"
  instance_type               = "${var.nat_instance_type}"
  key_name                    = "${var.aws_key_name}"
  vpc_security_group_ids      = "${aws_security_group.nat.*.id}"
  subnet_id                   = "${element(aws_subnet.public.*.id, (var.single_nat_gateway ? 0 : count.index))}"
  associate_public_ip_address = true
  source_dest_check           = false

  tags = "${merge(map("Name", format("%s-nat-%s", var.vpc_name, element(var.azs, (var.single_nat_instance ? 0 : count.index)))), var.tags)}"
}

resource "aws_eip_association" "nat_eip_assoc" {
  count         = "${var.enable_nat_instance ? local.nat_count : 0}"
  instance_id   = "${element(aws_instance.nat.*.id, count.index)}"
  allocation_id = local.nat_ips[0][var.single_nat_gateway ? 0 : count.index]
}

resource "aws_route" "private_nat_instance" {
  count = "${var.enable_nat_instance ? local.nat_instance_count : 0}"

  route_table_id         = "${element(aws_route_table.private.*.id, (var.single_nat_instance ? 0 : count.index))}"
  destination_cidr_block = "0.0.0.0/0"
  instance_id            = "${var.single_nat_instance ? element(aws_instance.nat.*.id, 0) : element(aws_instance.nat.*.id,  count.index)}"

  timeouts {
    create = "5m"
  }
}
