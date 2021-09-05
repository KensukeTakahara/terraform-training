output "vpc_id" {
  value = aws_vpc.example.id
}

output "public_subnet_ids" {
  value = [aws_subnet.public_1a.id, aws_subnet.public_1c.id]
}

output "private_subnet_ids" {
  value = [aws_subnet.private_1a.id, aws_subnet.private_1c.id]
}

output "cidr_block" {
  value = aws_vpc.example.cidr_block
}
