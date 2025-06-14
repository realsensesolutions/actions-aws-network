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
  description = "The NAT Gateway ID (empty if disabled)"
  value       = try(var.enable_nat_gateway ? aws_nat_gateway.main[0].id : "", "")
}

output "egress_only_gateway_id" {
  description = "The Egress-Only Internet Gateway ID"
  value       = var.enable_egress_only_gateway ? aws_egress_only_internet_gateway.main[0].id : null
}

output "vpc_ipv6_cidr_block" {
  description = "The IPv6 CIDR block of the VPC"
  value       = aws_vpc.main.ipv6_cidr_block
}

output "sg_public_id" {
  description = "The public security group ID"
  value       = aws_security_group.public.id
}

output "sg_private_id" {
  description = "The private security group ID"
  value       = aws_security_group.private.id
}