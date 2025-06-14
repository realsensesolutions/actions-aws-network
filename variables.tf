variable "instance" {
  description = "Instance name for this network infrastructure, this is taken from actions-aws-backend-setup outputs, ensure that actions runs before actions-aws-network"
}

variable "enable_nat_gateway" {
  description = "Enable NAT Gateway for IPv4 internet access from private subnets"
  type        = bool
  default     = false
}

variable "enable_egress_only_gateway" {
  description = "Enable Egress-Only Internet Gateway for IPv6 internet access from private subnets"
  type        = bool
  default     = true
}