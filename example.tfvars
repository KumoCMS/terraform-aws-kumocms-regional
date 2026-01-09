# Example Terraform Variables for KumoCMS Regional Deployment
# Copy this file to terraform.tfvars and customize for your deployment

# ==================== Core Configuration ====================

project_name = "kumocms"
environment  = "dev"
aws_region   = "us-east-1"

# ==================== Lambda Configuration ====================

lambda_deployment_package_path = "./lambda/kumocms-lambda.zip"
lambda_handler                 = "src.handlers.api.main.lambda_handler"
lambda_runtime                 = "python3.12"
lambda_memory_size             = 512
lambda_timeout                 = 30

# ==================== Storage Configuration ====================

s3_bucket_name      = "kumocms-dev-documents-us-east-1"
enable_s3_versioning = true

# Optional: S3 Lifecycle rules
# s3_lifecycle_rules = [
#   {
#     id                            = "archive-old-versions"
#     enabled                       = true
#     prefix                        = ""
#     expiration_days               = 0  # 0 means never expire current version
#     noncurrent_version_expiration = 90 # Delete old versions after 90 days
#   },
#   {
#     id                            = "delete-old-documents"
#     enabled                       = false
#     prefix                        = "temp/"
#     expiration_days               = 30
#     noncurrent_version_expiration = 7
#   }
# ]

# ==================== Database Configuration ====================

dynamodb_table_name = "kumocms-global-metadata"

# ==================== API Gateway Configuration ====================

api_gateway_stage_name    = "v1"
api_gateway_endpoint_type = "REGIONAL" # or "PRIVATE"
enable_api_gateway_logs   = true

# ==================== Authentication Configuration ====================

# Option 1: API Key Authentication (default)
auth_method                = "api_key"
api_authorizer_secrets_arn = "arn:aws:secretsmanager:us-east-1:123456789012:secret:kumocms/api-keys"

# Option 2: AWS Cognito Authentication
# auth_method = "cognito"

# Option 2a: Create new Cognito User Pool
# create_cognito_user_pool      = true
# cognito_password_min_length   = 12
# cognito_mfa_configuration     = "OPTIONAL"
# cognito_deletion_protection   = true
# cognito_callback_urls         = ["https://app.example.com/callback"]
# cognito_logout_urls           = ["https://app.example.com/logout"]
# cognito_domain_prefix         = "kumocms-dev"

# Option 2b: Use existing Cognito User Pool
# create_cognito_user_pool = false
# cognito_user_pool_arn    = "arn:aws:cognito-idp:us-east-1:123456789012:userpool/us-east-1_ABC123"

# ==================== Private API Configuration ====================
# Only needed if api_gateway_endpoint_type = "PRIVATE"

# Admin mode: Create VPC endpoint
# create_vpc_endpoint = true
# vpc_id              = "vpc-12345678"
# subnet_ids          = ["subnet-11111111", "subnet-22222222"]
# security_group_ids  = ["sg-33333333"]  # Optional, will create if not provided

# Power user mode: Use existing VPC endpoint
# create_vpc_endpoint = false
# vpc_endpoint_id     = "vpce-0abcdef1234567890"

# ==================== IAM Configuration ====================

# Admin mode: Create IAM roles (default)
create_iam_roles = true

# Power user mode: Use pre-created IAM roles
# create_iam_roles                            = false
# lambda_api_role_arn                         = "arn:aws:iam::123456789012:role/kumocms-lambda-api"
# lambda_authorizer_role_arn                  = "arn:aws:iam::123456789012:role/kumocms-lambda-authorizer"
# lambda_event_processor_role_arn             = "arn:aws:iam::123456789012:role/kumocms-lambda-event-processor"
# api_gateway_authorizer_invocation_role_arn  = "arn:aws:iam::123456789012:role/kumocms-api-gateway-authorizer"

# ==================== Feature Flags ====================

enable_eventbridge_metadata_extraction = true
enable_dlq                             = true
enable_waf                             = false
# waf_web_acl_arn = "arn:aws:wafv2:us-east-1:123456789012:regional/webacl/kumocms-waf/a1234567-b890-1234-c567-d890e1234567"

# ==================== Tags ====================

tags = {
  Team        = "Platform"
  CostCenter  = "Engineering"
  Environment = "Development"
  ManagedBy   = "Terraform"
}
