# Copyright (c) KumoCMS Contributors
# SPDX-License-Identifier: MIT

# ==================== CloudWatch Log Groups ====================
# Centralized logging for Lambda functions and API Gateway
# 14-day retention for cost optimization while maintaining audit trail

resource "aws_cloudwatch_log_group" "api_handler" {
  name              = "/aws/lambda/${aws_lambda_function.api_handler.function_name}"
  retention_in_days = 14

  tags = local.common_tags
}

resource "aws_cloudwatch_log_group" "authorizer" {
  count             = local.use_api_key_auth ? 1 : 0
  name              = "/aws/lambda/${aws_lambda_function.authorizer[0].function_name}"
  retention_in_days = 14

  tags = local.common_tags
}

resource "aws_cloudwatch_log_group" "event_processor" {
  count             = var.enable_eventbridge_metadata_extraction ? 1 : 0
  name              = "/aws/lambda/${aws_lambda_function.event_processor[0].function_name}"
  retention_in_days = 14

  tags = local.common_tags
}

resource "aws_cloudwatch_log_group" "api_gateway" {
  count             = var.enable_api_gateway_logs ? 1 : 0
  name              = "/aws/apigateway/${local.resource_prefix}"
  retention_in_days = 14

  tags = local.common_tags
}
