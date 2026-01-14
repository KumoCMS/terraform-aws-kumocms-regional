# Copyright (c) KumoCMS Contributors
# SPDX-License-Identifier: MIT

# ==================== Lambda Functions ====================
# Lambda functions for API handling, authentication, and event processing
# Supports conditional creation based on authentication method and feature flags

# API Handler Lambda
resource "aws_lambda_function" "api_handler" {
  filename         = var.lambda_deployment_package_path
  function_name    = "${local.resource_prefix}-api-handler"
  role             = local.lambda_api_role_arn
  handler          = var.lambda_handler
  source_code_hash = filebase64sha256(var.lambda_deployment_package_path)
  runtime          = var.lambda_runtime
  memory_size      = var.lambda_memory_size
  timeout          = var.lambda_timeout

  environment {
    variables = {
      S3_BUCKET_NAME      = aws_s3_bucket.documents.id
      DYNAMODB_TABLE_NAME = local.dynamodb_table_name
      SECRETS_ARN         = local.api_authorizer_secrets_arn
    }
  }

  dynamic "dead_letter_config" {
    for_each = var.enable_dlq ? [1] : []
    content {
      target_arn = aws_sqs_queue.dlq[0].arn
    }
  }

  tags = merge(
    local.common_tags,
    {
      Name = "${local.resource_prefix}-api-handler"
    }
  )
}

# Lambda Authorizer
resource "aws_lambda_function" "authorizer" {
  count            = local.use_api_key_auth ? 1 : 0
  filename         = var.lambda_deployment_package_path
  function_name    = "${local.resource_prefix}-authorizer"
  role             = local.lambda_authorizer_role_arn
  handler          = "src.handlers.auth_validator.lambda_handler"
  source_code_hash = filebase64sha256(var.lambda_deployment_package_path)
  runtime          = var.lambda_runtime
  memory_size      = 256
  timeout          = 10

  environment {
    variables = {
      SECRETS_ARN = local.api_authorizer_secrets_arn
    }
  }

  tags = merge(
    local.common_tags,
    {
      Name = "${local.resource_prefix}-authorizer"
    }
  )
}

# Event Processor Lambda
resource "aws_lambda_function" "event_processor" {
  count            = var.enable_eventbridge_metadata_extraction ? 1 : 0
  filename         = var.lambda_deployment_package_path
  function_name    = "${local.resource_prefix}-event-processor"
  role             = local.lambda_event_processor_role_arn
  handler          = "src.handlers.event_processor.lambda_handler"
  source_code_hash = filebase64sha256(var.lambda_deployment_package_path)
  runtime          = var.lambda_runtime
  memory_size      = var.lambda_memory_size
  timeout          = 60

  environment {
    variables = {
      S3_BUCKET_NAME      = aws_s3_bucket.documents.id
      DYNAMODB_TABLE_NAME = var.dynamodb_table_name
      AWS_REGION          = var.aws_region
    }
  }

  tags = merge(
    local.common_tags,
    {
      Name = "${local.resource_prefix}-event-processor"
    }
  )
}

# Lambda permission for API Gateway
resource "aws_lambda_permission" "api_gateway" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.api_handler.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.main.execution_arn}/*/*"
}

# Lambda permission for EventBridge
resource "aws_lambda_permission" "eventbridge" {
  count         = var.enable_eventbridge_metadata_extraction ? 1 : 0
  statement_id  = "AllowEventBridgeInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.event_processor[0].function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.metadata_extraction[0].arn
}
