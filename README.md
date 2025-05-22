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
| `instance` | <p>Unique identifier for infrastructure (optional, will use INSTANCE_NAME env var if available)</p> | `false` | `my-network` |
<!-- action-docs-inputs source="action.yml" -->

<!-- action-docs-outputs source="action.yml" -->
## Outputs

| name | description |
| --- | --- |
| `vpc_id` | <p>VPC ID</p> |
| `subnet_public_id` | <p>Public subnet ID</p> |
| `subnet_private_id` | <p>Private subnet ID</p> |
| `nat_gateway_id` | <p>NAT Gateway ID</p> |
| `sg_public_id` | <p>Public Security Group ID</p> |
| `sg_private_id` | <p>Private Security Group ID</p> |
| `instance` | <p>Instance name used for resources</p> |
<!-- action-docs-outputs source="action.yml" -->

## Output Environment Variables (TF_VAR_)
| name | description |
| --- | --- |
| `TF_VAR_vpc_id` | <p>VPC ID for use in subsequent Terraform</p> |
| `TF_VAR_subnet_public_id` | <p>Public subnet ID for use in subsequent Terraform</p> |
| `TF_VAR_subnet_private_id` | <p>Private subnet ID for use in subsequent Terraform</p> |
| `TF_VAR_nat_gateway_id` | <p>NAT Gateway ID for use in subsequent Terraform</p> |
| `TF_VAR_sg_public_id` | <p>Public Security Group ID for use in subsequent Terraform</p> |
| `TF_VAR_sg_private_id` | <p>Private Security Group ID for use in subsequent Terraform</p> |

## Network Architecture Created
- **VPC**: 10.0.0.0/16 with DNS support enabled
- **Public Subnet**: 10.0.1.0/24 (AZ-a) with auto-assign public IP
- **Private Subnet**: 10.0.2.0/24 (AZ-b)
- **Internet Gateway**: For public internet access
- **NAT Gateway**: In public subnet for private subnet internet access
- **Route Tables**: Configured for public/private routing
- **Security Groups**:
  - **Public SG**: Allows all inbound/outbound traffic
  - **Private SG**: Allows traffic only from within VPC

## Sample Usage

### With setup action providing INSTANCE_NAME
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
      - uses: alonch/actions-aws-network@main
        # No instance input needed - uses INSTANCE_NAME from previous step
      - name: Deploy application to VPC
        run: |
          echo "VPC ID: $TF_VAR_vpc_id"
          echo "Public Subnet: $TF_VAR_subnet_public_id"
          echo "Private Subnet: $TF_VAR_subnet_private_id"
          # Your application deployment here using the network variables
```

### Standalone usage
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
      - uses: alonch/actions-aws-network@main
        with:
          instance: demo
      - name: Deploy application to VPC
        run: |
          echo "VPC ID: $TF_VAR_vpc_id"
          echo "Public Subnet: $TF_VAR_subnet_public_id"
          echo "Private Subnet: $TF_VAR_subnet_private_id"
          # Your application deployment here using the network variables
```