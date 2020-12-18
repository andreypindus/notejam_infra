output "public_subnet_id" {
  value = aws_subnet.new_public_subnet.*.id
}

output "private_subnet_id" {
  value = aws_subnet.new_private_subnet.*.id
}

output "new_vpc_id" {
  value = aws_vpc.new_vpc.id
}

output "vpc_cidr" {
  value = aws_vpc.new_vpc.cidr_block
}
