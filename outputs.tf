# Copyright (c) KumoCMS Contributors
# SPDX-License-Identifier: MIT

# ==================== Module Outputs ====================
# Exported values for use by other modules or for user reference
# Includes API endpoints, resource ARNs, and configuration details

output "api_gateway_endpoint" {
  description = "API Gateway endpoint URL"
  value       = aws_api_gateway_stage.main.invoke_url
}

output "api_gateway_id" {
  description = "API Gateway REST API ID"
  value       = aws_api_gateway_rest_api.main.id
}

output "api_gateway_stage" {
  description = "API Gateway stage name"
  value       = aws_api_gateway_stage.main.stage_name
}

output "s3_bucket_name" {
  description = "S3 bucket name for document storage"
  value       = aws_s3_bucket.documents.id
}

output "s3_bucket_arn" {
  description = "S3 bucket ARN"
  value       = aws_s3_bucket.documents.arn
}

output "lambda_api_handler_arn" {
  description = "ARN of the API handler Lambda function"
  value       = aws_lambda_function.api_handler.arn
}

output "lambda_api_handler_name" {
  description = "Name of the API handler Lambda function"
  value       = aws_lambda_function.api_handler.function_name
}

output "lambda_authorizer_arn" {
  description = "ARN of the Lambda authorizer function (if using API key auth)"
  value       = local.use_api_key_auth && length(aws_lambda_function.authorizer) > 0 ? aws_lambda_function.authorizer[0].arn : null
}

output "lambda_authorizer_name" {
  description = "Name of the Lambda authorizer function (if using API key auth)"
  value       = local.use_api_key_auth && length(aws_lambda_function.authorizer) > 0 ? aws_lambda_function.authorizer[0].function_name : null
}

output "lambda_event_processor_arn" {
  description = "ARN of the event processor Lambda function (if enabled)"
  value       = var.enable_eventbridge_metadata_extraction ? aws_lambda_function.event_processor[0].arn : null
}

output "lambda_event_processor_name" {
  description = "Name of the event processor Lambda function (if enabled)"
  value       = var.enable_eventbridge_metadata_extraction ? aws_lambda_function.event_processor[0].function_name : null
}

output "dlq_url" {
  description = "URL of the Dead Letter Queue (if enabled)"
  value       = var.enable_dlq ? aws_sqs_queue.dlq[0].url : null
}

output "dlq_arn" {
  description = "ARN of the Dead Letter Queue (if enabled)"
  value       = var.enable_dlq ? aws_sqs_queue.dlq[0].arn : null
}

output "eventbridge_rule_arn" {
  description = "ARN of the EventBridge rule for metadata extraction (if enabled)"
  value       = var.enable_eventbridge_metadata_extraction ? aws_cloudwatch_event_rule.metadata_extraction[0].arn : null
}

output "vpc_endpoint_id" {
  description = "ID of the VPC endpoint for private API Gateway (if created)"
  value       = local.is_private_api && var.create_vpc_endpoint ? aws_vpc_endpoint.api_gateway[0].id : null
}

output "vpc_endpoint_dns_entries" {
  description = "DNS entries for the VPC endpoint (if created)"
  value       = local.is_private_api && var.create_vpc_endpoint ? aws_vpc_endpoint.api_gateway[0].dns_entry : null
}

output "api_gateway_endpoint_type" {
  description = "API Gateway endpoint type (REGIONAL or PRIVATE)"
  value       = var.api_gateway_endpoint_type
}

output "auth_method" {
  description = "Authentication method used (api_key or cognito)"
  value       = var.auth_method
}

output "cognito_user_pool_arn" {
  description = "Cognito User Pool ARN (if using Cognito auth)"
  value       = local.cognito_user_pool_arn
}

output "cognito_user_pool_id" {
  description = "Cognito User Pool ID (if created)"
  value       = var.create_cognito_user_pool && length(aws_cognito_user_pool.main) > 0 ? aws_cognito_user_pool.main[0].id : null
}

output "cognito_user_pool_endpoint" {
  description = "Cognito User Pool endpoint (if created)"
  value       = var.create_cognito_user_pool && length(aws_cognito_user_pool.main) > 0 ? aws_cognito_user_pool.main[0].endpoint : null
}

output "cognito_app_client_id" {
  description = "Cognito User Pool Client ID (if created)"
  value       = var.create_cognito_user_pool && length(aws_cognito_user_pool_client.main) > 0 ? aws_cognito_user_pool_client.main[0].id : null
}

output "cognito_domain" {
  description = "Cognito User Pool domain (if created)"
  value       = var.create_cognito_user_pool && var.cognito_domain_prefix != null && length(aws_cognito_user_pool_domain.main) > 0 ? "https://${aws_cognito_user_pool_domain.main[0].domain}.auth.${var.aws_region}.amazoncognito.com" : null
}

output "dynamodb_table_name" {
  description = "DynamoDB table name (created or provided)"
  value       = local.dynamodb_table_name
}

output "dynamodb_table_arn" {
  description = "DynamoDB table ARN (if created)"
  value       = var.create_dynamodb_table && length(aws_dynamodb_table.metadata) > 0 ? aws_dynamodb_table.metadata[0].arn : null
}

output "dynamodb_table_stream_arn" {
  description = "DynamoDB table stream ARN (if created)"
  value       = var.create_dynamodb_table && length(aws_dynamodb_table.metadata) > 0 ? aws_dynamodb_table.metadata[0].stream_arn : null
}
