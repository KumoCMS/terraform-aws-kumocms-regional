# KumoCMS Terraform Module - Quick Reference

## Quick Start

```bash
# 1. Clone the repository
git clone https://github.com/kumocms/terraform-aws-kumocms-regional.git
cd terraform-aws-kumocms-regional

# 2. Copy example configuration
cp example.tfvars terraform.tfvars

# 3. Edit configuration
vim terraform.tfvars

# 4. Initialize Terraform
terraform init

# 5. Plan deployment
terraform plan

# 6. Apply configuration
terraform apply
```

## Common Configurations

### 1. Basic Public API with API Key Auth
```hcl
module "kumocms" {
  source = "git::https://github.com/kumocms/terraform-aws-kumocms-regional.git?ref=v1.0.0"
  
  project_name                   = "kumocms"
  environment                    = "prod"
  aws_region                     = "us-east-1"
  lambda_deployment_package_path = "./lambda.zip"
  s3_bucket_name                 = "kumocms-prod-docs"
  dynamodb_table_name            = "kumocms-prod-metadata"
  api_authorizer_secrets_arn     = "arn:aws:secretsmanager:..."
}
```

### 2. Public API with Cognito (New User Pool)
```hcl
module "kumocms" {
  source = "..."
  
  auth_method              = "cognito"
  create_cognito_user_pool = true
  cognito_domain_prefix    = "kumocms-prod"
  
  # ... other required variables
}
```

### 3. Private API (Admin Mode)
```hcl
module "kumocms" {
  source = "..."
  
  api_gateway_endpoint_type = "PRIVATE"
  create_vpc_endpoint       = true
  vpc_id                    = "vpc-12345678"
  subnet_ids                = ["subnet-11111111", "subnet-22222222"]
  
  # ... other required variables
}
```

### 4. Power User Mode
```hcl
module "kumocms" {
  source = "..."
  
  create_iam_roles    = false
  lambda_api_role_arn = "arn:aws:iam::..."
  
  # ... other pre-created role ARNs
}
```

## Variable Quick Reference

### Required Variables
- `environment` - Environment name (dev/staging/prod)
- `aws_region` - AWS region
- `lambda_deployment_package_path` - Path to Lambda ZIP
- `s3_bucket_name` - Unique S3 bucket name
- `dynamodb_table_name` - DynamoDB table name
- `api_authorizer_secrets_arn` - Secrets Manager ARN (for API key auth)

### Important Optional Variables
- `auth_method` - "api_key" (default) or "cognito"
- `create_cognito_user_pool` - true/false (default: false)
- `api_gateway_endpoint_type` - "REGIONAL" (default) or "PRIVATE"
- `create_iam_roles` - true (default) or false
- `enable_eventbridge_metadata_extraction` - true (default) or false
- `enable_dlq` - true (default) or false

## Output Quick Reference

### Essential Outputs
- `api_gateway_endpoint` - API invoke URL
- `cognito_user_pool_id` - User Pool ID (if created)
- `cognito_app_client_id` - App Client ID (if created)
- `s3_bucket_name` - Document storage bucket
- `lambda_api_handler_arn` - Main Lambda function ARN

## API Endpoints

| Method | Path | Auth | Description |
|--------|------|------|-------------|
| GET | /healthcheck | None | Health check |
| GET | /documents | Required | List documents |
| POST | /documents | Required | Upload document |
| GET | /documents/{id} | Required | Retrieve document |
| PUT | /documents/{id} | Required | Replace document |
| DELETE | /documents/{id} | Required | Delete document |
| POST | /documents/{id}/archive | Required | Archive document |
| POST | /documents/{id}/restore | Required | Restore document |

## Authentication

### API Key
Store in Secrets Manager:
```json
{
  "api_key": "your-primary-key",
  "api_key_previous": "your-previous-key"
}
```

Include in requests:
```bash
curl -H "Authorization: your-api-key" \
  https://api-id.execute-api.region.amazonaws.com/v1/documents
```

### Cognito
1. Authenticate with User Pool
2. Get access token
3. Include in requests:
```bash
curl -H "Authorization: Bearer <access-token>" \
  https://api-id.execute-api.region.amazonaws.com/v1/documents
```

## Troubleshooting

### Issue: VPC Endpoint Creation Failed
**Solution**: Verify `vpc_id` and `subnet_ids` are correct

### Issue: Lambda Permission Denied
**Solution**: Check IAM role has required permissions or set `create_iam_roles = true`

### Issue: API Returns 401
**Solution**: Verify API key in Secrets Manager or Cognito token is valid

### Issue: DynamoDB Access Denied
**Solution**: Ensure DynamoDB table exists and IAM role has permissions

## File Structure
```
terraform-aws-kumocms-regional/
├── *.tf                  # Terraform configuration files
├── README.md             # Full documentation
├── example.tfvars        # Example configuration
├── CONTRIBUTING.md       # Contribution guide
└── .claude.md/.gemini.md # AI context files
```

## Commands

```bash
# Format code
terraform fmt -recursive

# Validate configuration
terraform validate

# Plan changes
terraform plan -var-file=terraform.tfvars

# Apply changes
terraform apply -var-file=terraform.tfvars

# Show outputs
terraform output

# Destroy infrastructure
terraform destroy -var-file=terraform.tfvars
```

## Links

- **Documentation**: [README.md](README.md)
- **Examples**: [example.tfvars](example.tfvars)
- **Contributing**: [CONTRIBUTING.md](CONTRIBUTING.md)
- **Lambda Code**: [kumocms-lambda-python](https://github.com/kumocms/kumocms-lambda-python)
- **Project Site**: [kumocms.github.io](https://kumocms.github.io)

## Support

- **Issues**: [GitHub Issues](https://github.com/kumocms/terraform-aws-kumocms-regional/issues)
- **Discussions**: [GitHub Discussions](https://github.com/kumocms/terraform-aws-kumocms-regional/discussions)

---

For detailed documentation, see [README.md](README.md)
