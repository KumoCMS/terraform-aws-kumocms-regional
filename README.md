# terraform-aws-kumocms-regional

A reusable Terraform module for provisioning regional KumoCMS resources on AWS. This module creates all the infrastructure needed to deploy KumoCMS in a single AWS region, including API Gateway, Lambda functions, S3 storage, and supporting services.

## Features

- **API Gateway**: RESTful API with Lambda integration and custom JWT authorizer
- **Public & Private API Modes**: Support for public (REGIONAL) or private (VPC-only) API Gateway endpoints
- **Lambda Functions**: API handlers, custom authorizer, and optional event processor for metadata extraction
- **S3 Storage**: Encrypted document storage with versioning and lifecycle policies
- **DynamoDB Integration**: Metadata storage with support for Global Tables
- **EventBridge** (Optional): Automated metadata extraction on document upload
- **SQS Dead Letter Queue**: Failed operation retry and error handling
- **IAM Roles**: Least-privilege access policies for all Lambda functions (supports both admin and power user modes)
- **CloudWatch Logs**: Centralized logging for API Gateway and Lambda functions
- **Optional WAF**: Web Application Firewall integration for API protection
- **VPC Endpoint**: Private API Gateway deployment with VPC endpoint support

## Architecture

This module provisions the following AWS resources:

```
┌─────────────────┐
│   API Gateway   │ ← REST API with custom authorizer
└────────┬────────┘
         │
         ├─→ Lambda Authorizer (JWT validation)
         │
         └─→ Lambda API Handler
                 │
                 ├─→ S3 Bucket (document storage)
                 ├─→ DynamoDB Table (metadata)
                 └─→ EventBridge → Lambda Event Processor (optional)
                              │
                              └─→ SQS DLQ (failed operations)
```

## Prerequisites

- Terraform >= 1.0
- AWS Provider >= 5.0
- Lambda deployment package from [kumocms-lambda-python](https://github.com/kumocms/kumocms-lambda-python)
- DynamoDB table (can be a Global Table for multi-region deployments)
- AWS Secrets Manager secret containing API keys

## Usage

### Basic Example

```hcl
module "kumocms_regional" {
  source = "git::https://github.com/kumocms/terraform-aws-kumocms-regional.git?ref=main"

  project_name = "kumocms"
  environment  = "prod"
  aws_region   = "us-east-1"

  # Lambda deployment package from kumocms-lambda-python
  lambda_deployment_package_path = "./lambda/kumocms-lambda.zip"

  # S3 bucket for document storage (must be globally unique)
  s3_bucket_name = "kumocms-prod-documents-us-east-1"

  # DynamoDB table name
  dynamodb_table_name = "kumocms-prod-metadata"

  # Secrets Manager ARN for API keys
  api_authorizer_secrets_arn = "arn:aws:secretsmanager:us-east-1:123456789012:secret:kumocms/api-keys-abcdef"

  # API Gateway configuration
  api_gateway_stage_name = "v1"

  # Enable optional features
  enable_s3_versioning                   = true
  enable_dlq                             = true
  enable_eventbridge_metadata_extraction = true  # Event-driven metadata extraction
  enable_api_gateway_logs                = true

  tags = {
    Team = "Platform"
    Cost = "Engineering"
  }
}
```

### Without Event-Driven Metadata Extraction

If you don't need automatic metadata extraction on file upload, you can disable the event-driven solution:

```hcl
module "kumocms_regional" {
  source = "git::https://github.com/kumocms/terraform-aws-kumocms-regional.git?ref=main"

  # ... other configuration ...

  # Disable event-driven solution (no EventBridge, no event processor Lambda)
  enable_eventbridge_metadata_extraction = false
}
```

### Multi-Region Deployment Example

```hcl
# Region 1: us-east-1
module "kumocms_us_east_1" {
  source = "git::https://github.com/kumocms/terraform-aws-kumocms-regional.git?ref=main"

  project_name = "kumocms"
  environment  = "prod"
  aws_region   = "us-east-1"

  lambda_deployment_package_path = "./lambda/kumocms-lambda.zip"
  s3_bucket_name                 = "kumocms-prod-documents-us-east-1"
  dynamodb_table_name            = "kumocms-prod-global-metadata"
  api_authorizer_secrets_arn     = "arn:aws:secretsmanager:us-east-1:123456789012:secret:kumocms/api-keys"

  providers = {
    aws = aws.us_east_1
  }
}

# Region 2: eu-west-1
module "kumocms_eu_west_1" {
  source = "git::https://github.com/kumocms/terraform-aws-kumocms-regional.git?ref=main"

  project_name = "kumocms"
  environment  = "prod"
  aws_region   = "eu-west-1"

  lambda_deployment_package_path = "./lambda/kumocms-lambda.zip"
  s3_bucket_name                 = "kumocms-prod-documents-eu-west-1"
  dynamodb_table_name            = "kumocms-prod-global-metadata"  # Same Global Table
  api_authorizer_secrets_arn     = "arn:aws:secretsmanager:eu-west-1:123456789012:secret:kumocms/api-keys"

  providers = {
    aws = aws.eu_west_1
  }
}
```

### With S3 Lifecycle Policies

```hcl
module "kumocms_regional" {
  source = "git::https://github.com/kumocms/terraform-aws-kumocms-regional.git?ref=main"

  # ... other configuration ...

  s3_lifecycle_rules = [
    {
      id                            = "archive-old-documents"
      enabled                       = true
      prefix                        = "documents/"
      expiration_days               = 365
      noncurrent_version_expiration = 90
    },
    {
      id                            = "delete-temp-files"
      enabled                       = true
      prefix                        = "temp/"
      expiration_days               = 7
      noncurrent_version_expiration = 1
    }
  ]
}
```

### DynamoDB Table Management

The module supports two modes for DynamoDB table management:

#### Option A: Create DynamoDB Global Table (Recommended)

The module can create and manage a DynamoDB global table with optimal settings for KumoCMS:

```hcl
module "kumocms_regional" {
  source = "git::https://github.com/kumocms/terraform-aws-kumocms-regional.git?ref=main"

  # ... other configuration ...

  # Create DynamoDB table with module
  create_dynamodb_table = true
  dynamodb_table_name   = "kumocms-prod-metadata"
}
```

This creates a table with:
- **Pay-per-request billing** (scales automatically)
- **Streams enabled** for EventBridge integration
- **Point-in-time recovery** for data protection
- **Server-side encryption** enabled
- **Global table replication** capability
- **Global Secondary Index** for document type queries

#### Option B: Use Existing DynamoDB Table

If you manage the DynamoDB table separately (e.g., for multi-region global tables):

```hcl
module "kumocms_regional" {
  source = "git::https://github.com/kumocms/terraform-aws-kumocms-regional.git?ref=main"

  # ... other configuration ...

  # Use existing DynamoDB table
  create_dynamodb_table = false
  dynamodb_table_name   = "kumocms-prod-global-metadata"  # Existing table name
}
```

**Required table schema:**
- Hash Key: `PK` (String)
- Range Key: `SK` (String)
- GSI: `DocumentTypeIndex` with hash key `documentType` and range key `uploadedAt`
- Streams: Enabled (for EventBridge integration)

### Authentication Methods

KumoCMS supports two authentication methods:

#### 1. API Key Authentication (Default)

Uses a custom Lambda authorizer with API keys stored in AWS Secrets Manager:

```hcl
module "kumocms_regional" {
  source = "git::https://github.com/kumocms/terraform-aws-kumocms-regional.git?ref=main"

  # ... other configuration ...

  # API Key authentication (default)
  auth_method                = "api_key"
  api_authorizer_secrets_arn = "arn:aws:secretsmanager:us-east-1:123456789012:secret:kumocms/api-keys"
}
```

The Secrets Manager secret should contain:
```json
{
  "api_key": "your-primary-api-key",
  "api_key_previous": "your-previous-api-key-for-rotation"
}
```

#### 2. AWS Cognito Authentication

Uses AWS Cognito User Pools for JWT-based authentication. You can either create a new User Pool or use an existing one.

**Option A: Create new Cognito User Pool**

```hcl
module "kumocms_regional" {
  source = "git::https://github.com/kumocms/terraform-aws-kumocms-regional.git?ref=main"

  # ... other configuration ...

  # Cognito authentication with new User Pool
  auth_method               = "cognito"
  create_cognito_user_pool  = true
  
  # Optional: Customize User Pool settings
  cognito_password_min_length   = 12
  cognito_mfa_configuration     = "OPTIONAL"
  cognito_deletion_protection   = true
  cognito_callback_urls         = ["https://app.example.com/callback"]
  cognito_logout_urls           = ["https://app.example.com/logout"]
  cognito_domain_prefix         = "kumocms-prod"  # Creates hosted UI
}
```

**Option B: Use existing Cognito User Pool**

```hcl
module "kumocms_regional" {
  source = "git::https://github.com/kumocms/terraform-aws-kumocms-regional.git?ref=main"

  # ... other configuration ...

  # Cognito authentication with existing User Pool
  auth_method            = "cognito"
  create_cognito_user_pool = false
  cognito_user_pool_arn  = "arn:aws:cognito-idp:us-east-1:123456789012:userpool/us-east-1_ABC123"
}
```

Note: When using Cognito authentication, the Lambda authorizer function is not created.

### Private API Gateway (VPC-only access)

#### Admin Mode - Module creates VPC endpoint

```hcl
module "kumocms_regional" {
  source = "git::https://github.com/kumocms/terraform-aws-kumocms-regional.git?ref=main"

  # ... other configuration ...

  # Private API Gateway configuration
  api_gateway_endpoint_type = "PRIVATE"
  
  # VPC configuration for creating VPC endpoint (admin mode)
  create_vpc_endpoint = true
  vpc_id              = "vpc-12345678"
  subnet_ids          = ["subnet-11111111", "subnet-22222222"]
  security_group_ids  = ["sg-33333333"]  # Optional, will create if not provided
}
```

#### Power User Mode - Use pre-created VPC endpoint

```hcl
module "kumocms_regional" {
  source = "git::https://github.com/kumocms/terraform-aws-kumocms-regional.git?ref=main"

  # ... other configuration ...

  # Private API Gateway with pre-created VPC endpoint (power user mode)
  api_gateway_endpoint_type = "PRIVATE"
  create_vpc_endpoint       = false
  vpc_endpoint_id           = "vpce-0abcdef1234567890"
}
```

### With WAF Integration

```hcl
# Create WAF Web ACL separately
resource "aws_wafv2_web_acl" "kumocms" {
  name  = "kumocms-prod-waf"
  scope = "REGIONAL"

  default_action {
    allow {}
  }

  rule {
    name     = "RateLimitRule"
    priority = 1

    action {
      block {}
    }

    statement {
      rate_based_statement {
        limit              = 2000
        aggregate_key_type = "IP"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "RateLimitRule"
      sampled_requests_enabled   = true
    }
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "kumocms-prod-waf"
    sampled_requests_enabled   = true
  }
}

# Use WAF with KumoCMS module
module "kumocms_regional" {
  source = "git::https://github.com/kumocms/terraform-aws-kumocms-regional.git?ref=main"

  # ... other configuration ...

  enable_waf      = true
  waf_web_acl_arn = aws_wafv2_web_acl.kumocms.arn
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| project_name | Name of the KumoCMS project (used for resource naming) | `string` | `"kumocms"` | no |
| environment | Environment name (e.g., dev, staging, prod) | `string` | n/a | yes |
| aws_region | AWS region for regional resources | `string` | n/a | yes |
| lambda_deployment_package_path | Path to the Lambda deployment package (ZIP file) from kumocms-lambda-python | `string` | n/a | yes |
| lambda_handler | Lambda function handler | `string` | `"src.handlers.api.main.lambda_handler"` | no |
| lambda_runtime | Lambda function runtime | `string` | `"python3.12"` | no |
| lambda_memory_size | Memory size for Lambda function (MB) | `number` | `512` | no |
| lambda_timeout | Timeout for Lambda function (seconds) | `number` | `30` | no |
| s3_bucket_name | Name for the S3 bucket for document storage (must be globally unique) | `string` | n/a | yes |
| enable_s3_versioning | Enable versioning for S3 bucket | `bool` | `true` | no |
| s3_lifecycle_rules | Lifecycle rules for S3 bucket | `list(object)` | `[]` | no |
| dynamodb_table_name | Name of the DynamoDB table for metadata storage | `string` | n/a | yes |
| api_gateway_stage_name | API Gateway deployment stage name | `string` | `"v1"` | no |
| api_gateway_endpoint_type | API Gateway endpoint type: REGIONAL (public) or PRIVATE (VPC-only) | `string` | `"REGIONAL"` | no |
| vpc_id | VPC ID for private API Gateway (required if api_gateway_endpoint_type is PRIVATE and create_vpc_endpoint is true) | `string` | `null` | no |
| subnet_ids | Subnet IDs for VPC endpoint (required if api_gateway_endpoint_type is PRIVATE and create_vpc_endpoint is true) | `list(string)` | `[]` | no |
| security_group_ids | Security group IDs for VPC endpoint (optional, will create default if not provided) | `list(string)` | `[]` | no |
| create_vpc_endpoint | Whether to create VPC endpoint for private API Gateway (admin mode) | `bool` | `true` | no |
| vpc_endpoint_id | Pre-created VPC endpoint ID for private API Gateway (required if api_gateway_endpoint_type is PRIVATE and create_vpc_endpoint is false) | `string` | `null` | no |
| enable_api_gateway_logs | Enable CloudWatch logging for API Gateway | `bool` | `true` | no |
| auth_method | Authentication method: 'api_key' (custom Lambda authorizer) or 'cognito' (AWS Cognito) | `string` | `"api_key"` | no |
| api_authorizer_secrets_arn | ARN of AWS Secrets Manager secret containing API keys for authorization (required if auth_method is 'api_key') | `string` | n/a | yes |
| create_cognito_user_pool | Whether to create a new Cognito User Pool (true) or use an existing one (false) | `bool` | `false` | no |
| cognito_user_pool_arn | ARN of existing AWS Cognito User Pool (required if auth_method is 'cognito' and create_cognito_user_pool is false) | `string` | `null` | no |
| cognito_password_min_length | Minimum password length for Cognito User Pool | `number` | `8` | no |
| cognito_mfa_configuration | MFA configuration for Cognito User Pool: OFF, ON, or OPTIONAL | `string` | `"OPTIONAL"` | no |
| cognito_deletion_protection | Enable deletion protection for Cognito User Pool | `bool` | `true` | no |
| cognito_callback_urls | List of callback URLs for Cognito User Pool Client | `list(string)` | `["http://localhost:3000/callback"]` | no |
| cognito_logout_urls | List of logout URLs for Cognito User Pool Client | `list(string)` | `["http://localhost:3000/logout"]` | no |
| cognito_domain_prefix | Domain prefix for Cognito User Pool (optional, creates hosted UI) | `string` | `null` | no |
| enable_waf | Enable AWS WAF for API Gateway | `bool` | `false` | no |
| waf_web_acl_arn | ARN of AWS WAF Web ACL (required if enable_waf is true) | `string` | `null` | no |
| enable_dlq | Enable Dead Letter Queue for failed Lambda invocations | `bool` | `true` | no |
| enable_eventbridge_metadata_extraction | Enable EventBridge rule for automated metadata extraction | `bool` | `true` | no |
| create_iam_roles | Whether to create IAM roles (admin mode) or use pre-created roles (power user mode) | `bool` | `true` | no |
| lambda_api_role_arn | ARN of pre-created IAM role for API handler Lambda (required if create_iam_roles is false) | `string` | `null` | no |
| lambda_authorizer_role_arn | ARN of pre-created IAM role for authorizer Lambda (required if create_iam_roles is false) | `string` | `null` | no |
| lambda_event_processor_role_arn | ARN of pre-created IAM role for event processor Lambda (required if create_iam_roles is false) | `string` | `null` | no |
| api_gateway_authorizer_invocation_role_arn | ARN of pre-created IAM role for API Gateway authorizer invocation (required if create_iam_roles is false) | `string` | `null` | no |
| tags | Additional tags to apply to all resources | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| api_gateway_endpoint | API Gateway endpoint URL |
| api_gateway_id | API Gateway REST API ID |
| api_gateway_stage | API Gateway stage name |
| api_gateway_endpoint_type | API Gateway endpoint type (REGIONAL or PRIVATE) |
| auth_method | Authentication method used (api_key or cognito) |
| cognito_user_pool_arn | Cognito User Pool ARN (if using Cognito auth) |
| cognito_user_pool_id | Cognito User Pool ID (if created) |
| cognito_user_pool_endpoint | Cognito User Pool endpoint (if created) |
| cognito_app_client_id | Cognito User Pool Client ID (if created) |
| cognito_domain | Cognito User Pool domain URL (if created with domain) |
| s3_bucket_name | S3 bucket name for document storage |
| s3_bucket_arn | S3 bucket ARN |
| lambda_api_handler_arn | ARN of the API handler Lambda function |
| lambda_api_handler_name | Name of the API handler Lambda function |
| lambda_authorizer_arn | ARN of the Lambda authorizer function (if using API key auth) |
| lambda_authorizer_name | Name of the Lambda authorizer function (if using API key auth) |
| lambda_event_processor_arn | ARN of the event processor Lambda function (if enabled) |
| lambda_event_processor_name | Name of the event processor Lambda function (if enabled) |
| dlq_url | URL of the Dead Letter Queue (if enabled) |
| dlq_arn | ARN of the Dead Letter Queue (if enabled) |
| eventbridge_rule_arn | ARN of the EventBridge rule for metadata extraction (if enabled) |
| vpc_endpoint_id | ID of the VPC endpoint for private API Gateway (if created) |
| vpc_endpoint_dns_entries | DNS entries for the VPC endpoint (if created) |

## Power User Mode - IAM Policy Examples

When deploying in power user mode (`create_iam_roles = false`), you must pre-create the following IAM roles. This section provides complete policy examples.

### Required IAM Roles

1. **Lambda API Handler Role** - Main API operations
2. **Lambda Authorizer Role** - API key validation (API key auth only)
3. **Lambda Event Processor Role** - Metadata extraction (if enabled)
4. **API Gateway Authorizer Invocation Role** - API Gateway to Lambda authorizer (API key auth only)

### Complete Terraform Example for IAM Roles

```hcl
locals {
  prefix = "${var.project_name}-${var.environment}"
}

# 1. Lambda API Handler Role
resource "aws_iam_role" "lambda_api" {
  name = "${local.prefix}-lambda-api-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "lambda.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_api_basic" {
  role       = aws_iam_role.lambda_api.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy" "lambda_api_permissions" {
  name = "${local.prefix}-lambda-api-policy"
  role = aws_iam_role.lambda_api.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject", "s3:PutObject",
          "s3:DeleteObject", "s3:ListBucket"
        ]
        Resource = [
          "arn:aws:s3:::YOUR_BUCKET_NAME",
          "arn:aws:s3:::YOUR_BUCKET_NAME/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "dynamodb:GetItem", "dynamodb:PutItem",
          "dynamodb:UpdateItem", "dynamodb:DeleteItem",
          "dynamodb:Query", "dynamodb:Scan"
        ]
        Resource = "arn:aws:dynamodb:REGION:ACCOUNT_ID:table/YOUR_TABLE_NAME"
      },
      {
        Effect   = "Allow"
        Action   = ["secretsmanager:GetSecretValue"]
        Resource = "arn:aws:secretsmanager:REGION:ACCOUNT_ID:secret:YOUR_SECRET_ARN"
      },
      {
        Effect   = "Allow"
        Action   = ["events:PutEvents"]
        Resource = "arn:aws:events:REGION:ACCOUNT_ID:event-bus/default"
      }
    ]
  })
}

# 2. Lambda Authorizer Role (API key auth only)
resource "aws_iam_role" "lambda_authorizer" {
  name = "${local.prefix}-lambda-authorizer-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "lambda.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_authorizer_basic" {
  role       = aws_iam_role.lambda_authorizer.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy" "lambda_authorizer_permissions" {
  name = "${local.prefix}-lambda-authorizer-policy"
  role = aws_iam_role.lambda_authorizer.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = ["secretsmanager:GetSecretValue"]
      Resource = "arn:aws:secretsmanager:REGION:ACCOUNT_ID:secret:YOUR_SECRET_ARN"
    }]
  })
}

# 3. Lambda Event Processor Role (optional)
resource "aws_iam_role" "lambda_event_processor" {
  name = "${local.prefix}-lambda-event-processor-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "lambda.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_event_processor_basic" {
  role       = aws_iam_role.lambda_event_processor.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy" "lambda_event_processor_permissions" {
  name = "${local.prefix}-lambda-event-processor-policy"
  role = aws_iam_role.lambda_event_processor.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["s3:GetObject"]
        Resource = "arn:aws:s3:::YOUR_BUCKET_NAME/*"
      },
      {
        Effect   = "Allow"
        Action   = ["dynamodb:UpdateItem"]
        Resource = "arn:aws:dynamodb:REGION:ACCOUNT_ID:table/YOUR_TABLE_NAME"
      }
    ]
  })
}

# 4. API Gateway Authorizer Invocation Role (API key auth only)
resource "aws_iam_role" "api_gateway_authorizer_invocation" {
  name = "${local.prefix}-api-gateway-auth-invocation-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "apigateway.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy" "api_gateway_authorizer_invocation" {
  name = "${local.prefix}-api-gateway-auth-invocation-policy"
  role = aws_iam_role.api_gateway_authorizer_invocation.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = ["lambda:InvokeFunction"]
      Resource = "arn:aws:lambda:REGION:*:function:${local.prefix}-authorizer"
    }]
  })
}

# Outputs
output "lambda_api_role_arn" {
  value = aws_iam_role.lambda_api.arn
}

output "lambda_authorizer_role_arn" {
  value = aws_iam_role.lambda_authorizer.arn
}

output "lambda_event_processor_role_arn" {
  value = aws_iam_role.lambda_event_processor.arn
}

output "api_gateway_authorizer_invocation_role_arn" {
  value = aws_iam_role.api_gateway_authorizer_invocation.arn
}
```

**Note**: Replace `YOUR_BUCKET_NAME`, `REGION`, `ACCOUNT_ID`, and `YOUR_TABLE_NAME` with your actual values.

## Lambda Function Code

This module expects a Lambda deployment package (ZIP file) from the [kumocms-lambda-python](https://github.com/kumocms/kumocms-lambda-python) repository. The package should contain:

- `src/handlers/api/main.py` - API handler for document operations (upload, retrieve, delete, etc.)
- `src/handlers/auth_validator.py` - Custom authorizer for JWT validation
- `src/handlers/event_processor.py` - Event processor for metadata extraction

### Building the Lambda Package

```bash
# Clone the kumocms-lambda-python repository
git clone https://github.com/kumocms/kumocms-lambda-python.git
cd kumocms-lambda-python

# Install dependencies
pip install -r requirements.txt -t ./package

# Create deployment package
cd package
zip -r ../kumocms-lambda.zip .
cd ..
zip -g kumocms-lambda.zip -r src/

# Use the package with this module
# lambda_deployment_package_path = "./kumocms-lambda.zip"
```

## Security Considerations

- **S3 Bucket**: Encryption at rest enabled by default, public access blocked
- **Lambda Functions**: Least-privilege IAM roles with minimal permissions
- **API Gateway**: Custom authorizer validates JWT tokens from AWS Secrets Manager
- **Secrets Manager**: API keys stored securely and rotated regularly
- **WAF**: Optional rate limiting and threat protection
- **VPC**: Lambda functions can be deployed in VPC for enhanced security (requires additional configuration)

## Cost Optimization

- **Lambda**: Pay-per-invocation with configurable memory and timeout
- **S3**: Lifecycle policies for automatic archival and deletion
- **DynamoDB**: On-demand billing or provisioned capacity
- **CloudWatch Logs**: Configurable retention periods (default: 14 days)
- **Dead Letter Queue**: Automatic cleanup of failed messages

## Contributing

Contributions are welcome! Please see the [KumoCMS Contributing Guidelines](https://github.com/kumocms/kumocms.github.io/blob/main/CONTRIBUTING.md) for details.

## License

This module is distributed under the MIT License. See [LICENSE](./LICENSE) for more information.

## Related Repositories

- [kumocms-lambda-python](https://github.com/kumocms/kumocms-lambda-python) - Lambda function code for KumoCMS API
- [kumocms.github.io](https://github.com/kumocms/kumocms.github.io) - KumoCMS documentation and architecture diagrams
- [kumocms-vault-internal](https://github.com/kumocms/kumocms-vault-internal) - Complete infrastructure reference implementation

## Support

For questions, issues, or feature requests, please open an issue in the [GitHub repository](https://github.com/kumocms/terraform-aws-kumocms-regional/issues).