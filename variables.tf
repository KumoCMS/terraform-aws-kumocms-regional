# Copyright (c) KumoCMS Contributors
# SPDX-License-Identifier: MIT

# ==================== Input Variables ====================
# Configuration parameters for KumoCMS regional deployment
# Supports flexible deployment modes: admin/power user, public/private API
# For detailed documentation, see README.md

# ==================== Core Configuration ====================

variable "project_name" {
  description = "Name of the KumoCMS project (used for resource naming)"
  type        = string
  default     = "kumocms"
}

variable "environment" {
  description = "Environment name (e.g., dev, staging, prod)"
  type        = string
}

variable "aws_region" {
  description = "AWS region for regional resources"
  type        = string
}

variable "lambda_deployment_package_path" {
  description = "Path to the Lambda deployment package (ZIP file) from kumocms-lambda-python"
  type        = string
}

variable "lambda_handler" {
  description = "Lambda function handler"
  type        = string
  default     = "src.handlers.api.main.lambda_handler"
}

variable "lambda_runtime" {
  description = "Lambda function runtime"
  type        = string
  default     = "python3.12"
}

variable "lambda_memory_size" {
  description = "Memory size for Lambda function (MB)"
  type        = number
  default     = 512
}

variable "lambda_timeout" {
  description = "Timeout for Lambda function (seconds)"
  type        = number
  default     = 30
}

variable "s3_bucket_name" {
  description = "Name for the S3 bucket for document storage (must be globally unique)"
  type        = string
}

variable "enable_s3_versioning" {
  description = "Enable versioning for S3 bucket"
  type        = bool
  default     = true
}

variable "s3_lifecycle_rules" {
  description = "Lifecycle rules for S3 bucket"
  type = list(object({
    id                            = string
    enabled                       = bool
    prefix                        = string
    expiration_days               = number
    noncurrent_version_expiration = number
  }))
  default = []
}

variable "create_dynamodb_table" {
  description = "Whether to create a new DynamoDB table (true) or use an existing one (false)"
  type        = bool
  default     = false
}

variable "dynamodb_table_name" {
  description = "Name of the DynamoDB table for metadata storage. If create_dynamodb_table is true, this will be the name of the created table. If false, this should be the name of an existing table."
  type        = string
}

variable "api_gateway_stage_name" {
  description = "API Gateway deployment stage name"
  type        = string
  default     = "v1"
}

variable "api_gateway_endpoint_type" {
  description = "API Gateway endpoint type: REGIONAL (public) or PRIVATE (requires VPC endpoint)"
  type        = string
  default     = "REGIONAL"
  validation {
    condition     = contains(["REGIONAL", "PRIVATE"], var.api_gateway_endpoint_type)
    error_message = "api_gateway_endpoint_type must be either REGIONAL or PRIVATE."
  }
}

variable "vpc_id" {
  description = "VPC ID for private API Gateway (required if api_gateway_endpoint_type is PRIVATE and create_vpc_endpoint is true)"
  type        = string
  default     = null
}

variable "subnet_ids" {
  description = "Subnet IDs for VPC endpoint (required if api_gateway_endpoint_type is PRIVATE and create_vpc_endpoint is true)"
  type        = list(string)
  default     = []
}

variable "security_group_ids" {
  description = "Security group IDs for VPC endpoint (optional, will create default if not provided)"
  type        = list(string)
  default     = []
}

variable "create_vpc_endpoint" {
  description = "Whether to create VPC endpoint for private API Gateway (admin mode). Set to false for power user mode."
  type        = bool
  default     = true
}

variable "vpc_endpoint_id" {
  description = "Pre-created VPC endpoint ID for private API Gateway (required if api_gateway_endpoint_type is PRIVATE and create_vpc_endpoint is false)"
  type        = string
  default     = null
}

variable "enable_api_gateway_logs" {
  description = "Enable CloudWatch logging for API Gateway"
  type        = bool
  default     = true
}

variable "api_authorizer_secrets_arn" {
  description = "ARN of AWS Secrets Manager secret containing API keys for authorization"
  type        = string
  default     = null
}

variable "auth_method" {
  description = "Authentication method: 'api_key' (custom Lambda authorizer) or 'cognito' (AWS Cognito)"
  type        = string
  default     = "api_key"
  validation {
    condition     = contains(["api_key", "cognito"], var.auth_method)
    error_message = "auth_method must be either 'api_key' or 'cognito'."
  }
}

variable "create_cognito_user_pool" {
  description = "Whether to create a new Cognito User Pool (true) or use an existing one (false)"
  type        = bool
  default     = false
}

variable "cognito_user_pool_arn" {
  description = "ARN of existing AWS Cognito User Pool (required if auth_method is 'cognito' and create_cognito_user_pool is false)"
  type        = string
  default     = null
}

variable "cognito_password_min_length" {
  description = "Minimum password length for Cognito User Pool"
  type        = number
  default     = 8
}

variable "cognito_mfa_configuration" {
  description = "MFA configuration for Cognito User Pool: OFF, ON, or OPTIONAL"
  type        = string
  default     = "OPTIONAL"
  validation {
    condition     = contains(["OFF", "ON", "OPTIONAL"], var.cognito_mfa_configuration)
    error_message = "cognito_mfa_configuration must be OFF, ON, or OPTIONAL."
  }
}

variable "cognito_deletion_protection" {
  description = "Enable deletion protection for Cognito User Pool"
  type        = bool
  default     = true
}

variable "cognito_callback_urls" {
  description = "List of callback URLs for Cognito User Pool Client"
  type        = list(string)
  default     = ["http://localhost:3000/callback"]
}

variable "cognito_logout_urls" {
  description = "List of logout URLs for Cognito User Pool Client"
  type        = list(string)
  default     = ["http://localhost:3000/logout"]
}

variable "cognito_domain_prefix" {
  description = "Domain prefix for Cognito User Pool (optional, creates hosted UI)"
  type        = string
  default     = null
}

variable "enable_waf" {
  description = "Enable AWS WAF for API Gateway"
  type        = bool
  default     = false
}

variable "waf_web_acl_arn" {
  description = "ARN of AWS WAF Web ACL (required if enable_waf is true)"
  type        = string
  default     = null
}

variable "enable_dlq" {
  description = "Enable Dead Letter Queue for failed Lambda invocations"
  type        = bool
  default     = true
}

variable "enable_eventbridge_metadata_extraction" {
  description = "Enable EventBridge rule for automated metadata extraction"
  type        = bool
  default     = true
}

variable "tags" {
  description = "Additional tags to apply to all resources"
  type        = map(string)
  default     = {}
}

# ==================== Pre-created IAM Roles (Power User Mode) ====================

variable "create_iam_roles" {
  description = "Whether to create IAM roles (admin mode) or use pre-created roles (power user mode)"
  type        = bool
  default     = true
}

variable "lambda_api_role_arn" {
  description = "ARN of pre-created IAM role for API handler Lambda (required if create_iam_roles is false)"
  type        = string
  default     = null
}

variable "lambda_authorizer_role_arn" {
  description = "ARN of pre-created IAM role for authorizer Lambda (required if create_iam_roles is false)"
  type        = string
  default     = null
}

variable "lambda_event_processor_role_arn" {
  description = "ARN of pre-created IAM role for event processor Lambda (required if create_iam_roles is false)"
  type        = string
  default     = null
}

variable "api_gateway_authorizer_invocation_role_arn" {
  description = "ARN of pre-created IAM role for API Gateway to invoke authorizer (required if create_iam_roles is false)"
  type        = string
  default     = null
}
