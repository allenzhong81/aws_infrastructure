output "eips" {
  value       = "${aws_eip.nat.*.public_ip}"
  description = "Elastic IPs"
}

output "vpc_id" {
  value       = "${aws_vpc.this.id}"
  description = "vpc id"
}

output "internet_gate_way_id" {
  value = "${element(aws_internet_gateway.this.*.id, 0)}"
}

output "public_route_table_ids" {
  value = "${aws_route_table.public.*.id}"
}

output "private_route_table_ids" {
  value = "${aws_route_table.private.*.id}"
}

output "route_public_internet_gateway_ids" {
  value = "${aws_route.public_internet_gateway.*.id}"
}

output "public_subnets_ids" {
  value = "${aws_subnet.public.*.id}"
}

output "public_subnets_cidr_blocks" {
  value = "${aws_subnet.public.*.cidr_block}"
}

output "private_subnets_ids" {
  value = "${aws_subnet.private.*.id}"
}

output "private_subnets_cidr_blocks" {
  value = "${aws_subnet.private.*.cidr_block}"
}

output "nat_gateway_ids" {
  value = "${aws_nat_gateway.this.*.id}"
}

output "route_private_nat_gateway_ids" {
  value = "${aws_route.private_nat_gateway.*.id}"
}

output "nat_security_group_ids" {
  value = "${aws_security_group.nat.*.id}"
}

output "nat_instance_ids" {
  value = "${aws_instance.nat.*.id}"
}

output "route_private_nat_instance_ids" {
  value = "${aws_route.private_nat_instance.*.id}"
}
