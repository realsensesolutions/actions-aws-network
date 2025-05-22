output "vpc_id" {
  description = "The VPC ID"
  value       = aws_vpc.main.id
}

output "subnet_public_id" {
  description = "The first public subnet ID (backward compatibility)"
  value       = aws_subnet.public[0].id
}

output "subnet_private_id" {
  description = "The first private subnet ID (backward compatibility)"
  value       = aws_subnet.private[0].id
}

output "subnet_public_ids" {
  description = "All public subnet IDs (comma-separated)"
  value       = join(",", aws_subnet.public[*].id)
}

output "subnet_private_ids" {
  description = "All private subnet IDs (comma-separated)"
  value       = join(",", aws_subnet.private[*].id)
}

output "nat_gateway_id" {
  description = "The NAT Gateway ID"
  value       = aws_nat_gateway.main.id
}

output "sg_public_id" {
  description = "The public security group ID"
  value       = aws_security_group.public.id
}

output "sg_private_id" {
  description = "The private security group ID"
  value       = aws_security_group.private.id
}