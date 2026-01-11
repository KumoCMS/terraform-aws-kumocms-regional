# Copyright (c) KumoCMS Contributors
# SPDX-License-Identifier: MIT

# ==================== Local Variables ====================
# Computed values and conditional logic for resource creation
# Determines which IAM roles, VPC endpoints, and authorizers to use

locals {
  resource_prefix = "${var.project_name}-${var.environment}"
  common_tags = merge(
    {
      Project     = var.project_name
      Environment = var.environment
      ManagedBy   = "Terraform"
    },
    var.tags
  )

  # Determine which IAM roles to use (created or provided)
  lambda_api_role_arn                        = var.create_iam_roles ? aws_iam_role.lambda_api[0].arn : var.lambda_api_role_arn
  lambda_authorizer_role_arn                 = local.use_api_key_auth ? (var.create_iam_roles ? aws_iam_role.lambda_authorizer[0].arn : var.lambda_authorizer_role_arn) : null
  lambda_event_processor_role_arn            = var.enable_eventbridge_metadata_extraction ? (var.create_iam_roles ? aws_iam_role.lambda_event_processor[0].arn : var.lambda_event_processor_role_arn) : null
  api_gateway_authorizer_invocation_role_arn = local.use_api_key_auth ? (var.create_iam_roles ? aws_iam_role.api_gateway_authorizer_invocation[0].arn : var.api_gateway_authorizer_invocation_role_arn) : null

  # Determine VPC endpoint to use (created or provided)
  is_private_api      = var.api_gateway_endpoint_type == "PRIVATE"
  vpc_endpoint_id     = local.is_private_api ? (var.create_vpc_endpoint ? aws_vpc_endpoint.api_gateway[0].id : var.vpc_endpoint_id) : null
  create_sg_for_vpce  = local.is_private_api && var.create_vpc_endpoint && length(var.security_group_ids) == 0

  # Determine which authorizer to use based on auth_method
  use_api_key_auth = var.auth_method == "api_key"
  use_cognito_auth = var.auth_method == "cognito"
  authorizer_id    = local.use_api_key_auth ? aws_api_gateway_authorizer.api_key[0].id : aws_api_gateway_authorizer.cognito[0].id

  # Determine which Cognito User Pool ARN to use (created or provided)
  cognito_user_pool_arn = local.use_cognito_auth ? (
    var.create_cognito_user_pool ? aws_cognito_user_pool.main[0].arn : var.cognito_user_pool_arn
  ) : null

  # Determine DynamoDB table name (created or provided)
  dynamodb_table_name = var.create_dynamodb_table ? aws_dynamodb_table.metadata[0].name : var.dynamodb_table_name
}
