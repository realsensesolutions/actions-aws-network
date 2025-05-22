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

## Sample Usage

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

