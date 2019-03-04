output "eips" {
  value = ["${aws_eip.nat.*.public_ip}"]
  description = "Elastic IPs"
}

output "vpc_id" {
  value = "${aws_vpc.this.id}"
  description = "vpc id"
}

output "internet_gate_way_id" {
  value = "${element(aws_internet_gateway.this.*.id, 0)}"
}

output "aws_route_table_ids" {
  value = ["${aws_route_table.public.*.id}"]
}

output "aws_route_public_internet_gateway" {
  value = ["${aws_route.public_internet_gateway.*.id}"]
}


