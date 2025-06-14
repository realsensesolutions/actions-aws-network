<!-- action-docs-header source="action.yml" -->
## Action AWS Network Setup
<!-- action-docs-header source="action.yml" -->
![Demo Status](https://github.com/alonch/actions-aws-network/actions/workflows/on-push.yml/badge.svg)

<!-- action-docs-description source="action.yml" -->
## Description

Search or Create AWS VPC and network infrastructure
<!-- action-docs-description source="action.yml" -->

<!-- action-docs-inputs source="action.yml" -->
## Inputs

| name | description | required | default |
| --- | --- | --- | --- |
| `action` | <p>Action to perform: plan, apply, or destroy</p> | `false` | `apply` |
| `force-apply` | <p>Force terraform apply even if resources already exist</p> | `false` | `false` |
<!-- action-docs-inputs source="action.yml" -->

<!-- action-docs-outputs source="action.yml" -->
## Outputs

| name | description |
| --- | --- |
| `vpc_id` | <p>VPC ID</p> |
| `subnet_public_id` | <p>First public subnet ID (backward compatibility)</p> |
| `subnet_private_id` | <p>First private subnet ID (backward compatibility)</p> |
| `subnet_public_ids` | <p>All public subnet IDs (comma-separated)</p> |
| `subnet_private_ids` | <p>All private subnet IDs (comma-separated)</p> |
| `nat_gateway_id` | <p>NAT Gateway ID</p> |
| `sg_public_id` | <p>Public Security Group ID</p> |
| `sg_private_id` | <p>Private Security Group ID</p> |
<!-- action-docs-outputs source="action.yml" -->

## Output Environment Variables (TF_VAR_)
| name | description |
| --- | --- |
| `TF_VAR_vpc_id` | <p>VPC ID for use in subsequent Terraform</p> |
| `TF_VAR_subnet_public_id` | <p>First public subnet ID for use in subsequent Terraform</p> |
| `TF_VAR_subnet_private_id` | <p>First private subnet ID for use in subsequent Terraform</p> |
| `TF_VAR_subnet_public_ids` | <p>All public subnet IDs (comma-separated) for use in subsequent Terraform</p> |
| `TF_VAR_subnet_private_ids` | <p>All private subnet IDs (comma-separated) for use in subsequent Terraform</p> |
| `TF_VAR_nat_gateway_id` | <p>NAT Gateway ID for use in subsequent Terraform</p> |
| `TF_VAR_sg_public_id` | <p>Public Security Group ID for use in subsequent Terraform</p> |
| `TF_VAR_sg_private_id` | <p>Private Security Group ID for use in subsequent Terraform</p> |

## Network Architecture Created
- **VPC**: 10.0.0.0/16 with DNS support enabled
- **Public Subnets**: 2 subnets with /20 CIDR (4096 IPs each)
  - Public-1: 10.0.0.0/20 (AZ-a) with auto-assign public IP
  - Public-2: 10.0.16.0/20 (AZ-b) with auto-assign public IP
- **Private Subnets**: 2 subnets with /20 CIDR (4096 IPs each)
  - Private-1: 10.0.32.0/20 (AZ-a)
  - Private-2: 10.0.48.0/20 (AZ-b)
- **Internet Gateway**: For public internet access
- **NAT Gateway**: Single NAT in first public subnet for cost efficiency
- **Route Tables**: Configured for public/private routing (shared across subnets)
- **Security Groups**:
  - **Public SG**: Allows all inbound/outbound traffic
  - **Private SG**: Allows traffic only from within VPC

## Backend Configuration
This action automatically configures Terraform to use S3 remote backend:
- **Bucket**: Uses `$TF_BACKEND_s3` from backend setup action
- **DynamoDB Table**: Uses `$TF_BACKEND_dynamodb` from backend setup action
- **State Key**: `actions-aws-network/{INSTANCE_NAME}`

## Sample Usage

**📝 Note**: This action requires the backend setup action to run first to provide the S3 bucket and DynamoDB table for Terraform state management.

### Apply (default) - Create or find existing network
```yml
permissions:
  id-token: write
jobs:
  apply:
    runs-on: ubuntu-latest
    steps:
      - name: Check out repo
        uses: actions/checkout@v4
      - uses: aws-actions/configure-aws-credentials@v4
        with:
          aws-region: us-east-1
          role-to-assume: ${{ secrets.ROLE_ARN }}
          role-session-name: ${{ github.actor }}
      - uses: alonch/actions-aws-backend-setup@main
        with:
          instance: demo
      - uses: hashicorp/setup-terraform@v3
      - uses: alonch/actions-aws-network@main
        with:
          action: apply  # optional, this is the default
      - name: Deploy application to VPC
        run: |
          echo "VPC ID: $TF_VAR_vpc_id"
          echo "First Public Subnet: $TF_VAR_subnet_public_id"
          echo "First Private Subnet: $TF_VAR_subnet_private_id"
          echo "All Public Subnets: $TF_VAR_subnet_public_ids"
          echo "All Private Subnets: $TF_VAR_subnet_private_ids"
          # Use arrays in subsequent Terraform: split(",", var.subnet_public_ids)
```

### Plan - Show what would be created
```yml
      - uses: alonch/actions-aws-network@main
        with:
          action: plan
```

### Destroy - Remove network infrastructure
```yml
      - uses: alonch/actions-aws-network@main
        with:
          action: destroy
```

### Force Apply - Update existing infrastructure
```yml
      - uses: alonch/actions-aws-network@main
        with:
          action: apply
          force-apply: true
```
**Use Cases:**
- When Terraform configuration has changed (like adding subnets)
- When you need to update existing resources to match new configuration
- When resources exist but may not match current Terraform state

# AWS Network Infrastructure with IPv6 and Egress-Only Internet Gateway

This Terraform configuration creates a dual-stack (IPv4/IPv6) AWS VPC with support for both NAT Gateway and Egress-Only Internet Gateway for cost optimization.

## Architecture

- **VPC**: Dual-stack with IPv4 (10.0.0.0/16) and IPv6 CIDR blocks
- **Public Subnets**: 2 subnets with IPv4 and IPv6 support
- **Private Subnets**: 2 subnets with IPv4 and IPv6 support
- **Internet Gateway**: For public subnet internet access (IPv4 and IPv6)
- **NAT Gateway**: For private subnet IPv4 internet access (optional)
- **Egress-Only Internet Gateway**: For private subnet IPv6 internet access (optional)

## Cost Optimization Strategy

### Current State (NAT Gateway)
- NAT Gateway: ~$45-90/month + data processing charges
- Elastic IP: ~$3.65/month

### Target State (Egress-Only Internet Gateway)
- Egress-Only Internet Gateway: $0/month (no hourly charges)
- Data transfer: Same rates as NAT Gateway

## Migration Strategy

### Phase 1: Enable IPv6 Support (Current Implementation)
Both NAT Gateway and Egress-Only Internet Gateway are enabled by default, allowing for gradual migration:

```hcl
enable_nat_gateway = true           # Keep existing IPv4 connectivity
enable_egress_only_gateway = true   # Add IPv6 connectivity
```

### Phase 2: Test IPv6 Connectivity
1. Deploy Lambda functions in private subnets
2. Test external API calls over IPv6
3. Verify EFS access works with dual-stack
4. Monitor traffic patterns

### Phase 3: Disable NAT Gateway (Future)
Once IPv6 connectivity is validated:

```hcl
enable_nat_gateway = false          # Remove NAT Gateway
enable_egress_only_gateway = true   # Keep IPv6 connectivity
```

## Usage

### Basic Deployment
```yaml
- uses: your-org/actions-aws-network@main
  with:
    action: apply
```

### Custom Configuration
```yaml
- uses: your-org/actions-aws-network@main
  with:
    action: apply
  env:
    TF_VAR_enable_nat_gateway: "true"
    TF_VAR_enable_egress_only_gateway: "true"
```

## Outputs

- `vpc_id`: VPC ID
- `vpc_ipv6_cidr_block`: IPv6 CIDR block of the VPC
- `subnet_public_ids`: Public subnet IDs
- `subnet_private_ids`: Private subnet IDs
- `nat_gateway_id`: NAT Gateway ID (if enabled)
- `egress_only_gateway_id`: Egress-Only Internet Gateway ID (if enabled)
- `sg_public_id`: Public security group ID
- `sg_private_id`: Private security group ID

## Prerequisites for IPv6 Migration

1. **External Services**: Verify all external APIs support IPv6
2. **Lambda Runtime**: Ensure Lambda functions support IPv6 networking
3. **EFS**: Confirm EFS supports IPv6 in your region
4. **Application Code**: Check for hardcoded IPv4 addresses

## Testing Checklist

- [ ] Lambda functions can access internet via IPv6
- [ ] EFS mounts work with IPv6
- [ ] External API calls succeed over IPv6
- [ ] Security groups allow necessary IPv6 traffic
- [ ] Route tables correctly route IPv6 traffic

## Rollback Plan

If issues arise, disable Egress-Only Internet Gateway:

```hcl
enable_nat_gateway = true
enable_egress_only_gateway = false
```

## Monitoring

Use VPC Flow Logs to monitor traffic patterns:
- IPv4 traffic through NAT Gateway
- IPv6 traffic through Egress-Only Internet Gateway
- Identify optimization opportunities

