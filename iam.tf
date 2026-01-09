# Copyright (c) KumoCMS Contributors
# SPDX-License-Identifier: MIT

# ==================== IAM Roles and Policies ====================
# IAM roles and policies for Lambda functions with least-privilege access
# Supports both admin mode (creates roles) and power user mode (uses pre-created roles)
# Conditional creation based on create_iam_roles and feature flags

# Lambda Execution Role for API Handlers
resource "aws_iam_role" "lambda_api" {
  count = var.create_iam_roles ? 1 : 0
  name  = "${local.resource_prefix}-lambda-api-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = local.common_tags
}

resource "aws_iam_role_policy_attachment" "lambda_api_basic" {
  count      = var.create_iam_roles ? 1 : 0
  role       = aws_iam_role.lambda_api[0].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy" "lambda_api_permissions" {
  count = var.create_iam_roles ? 1 : 0
  name  = "${local.resource_prefix}-lambda-api-policy"
  role  = aws_iam_role.lambda_api[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:ListBucket"
        ]
        Resource = [
          aws_s3_bucket.documents.arn,
          "${aws_s3_bucket.documents.arn}/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "dynamodb:GetItem",
          "dynamodb:PutItem",
          "dynamodb:UpdateItem",
          "dynamodb:DeleteItem",
          "dynamodb:Query",
          "dynamodb:Scan"
        ]
        Resource = "arn:aws:dynamodb:${var.aws_region}:*:table/${var.dynamodb_table_name}"
      },
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue"
        ]
        Resource = var.api_authorizer_secrets_arn
      },
      {
        Effect = "Allow"
        Action = [
          "events:PutEvents"
        ]
        Resource = "arn:aws:events:${var.aws_region}:*:event-bus/default"
      }
    ]
  })
}

# Lambda Execution Role for Event Processor
resource "aws_iam_role" "lambda_event_processor" {
  count = var.create_iam_roles && var.enable_eventbridge_metadata_extraction ? 1 : 0
  name  = "${local.resource_prefix}-lambda-event-processor-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = local.common_tags
}

resource "aws_iam_role_policy_attachment" "lambda_event_processor_basic" {
  count      = var.create_iam_roles && var.enable_eventbridge_metadata_extraction ? 1 : 0
  role       = aws_iam_role.lambda_event_processor[0].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy" "lambda_event_processor_permissions" {
  count = var.create_iam_roles && var.enable_eventbridge_metadata_extraction ? 1 : 0
  name  = "${local.resource_prefix}-lambda-event-processor-policy"
  role  = aws_iam_role.lambda_event_processor[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject"
        ]
        Resource = "${aws_s3_bucket.documents.arn}/*"
      },
      {
        Effect = "Allow"
        Action = [
          "dynamodb:UpdateItem"
        ]
        Resource = "arn:aws:dynamodb:${var.aws_region}:*:table/${var.dynamodb_table_name}"
      }
    ]
  })
}

# Lambda Authorizer Role
resource "aws_iam_role" "lambda_authorizer" {
  count = var.create_iam_roles && local.use_api_key_auth ? 1 : 0
  name  = "${local.resource_prefix}-lambda-authorizer-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = local.common_tags
}

resource "aws_iam_role_policy_attachment" "lambda_authorizer_basic" {
  count      = var.create_iam_roles && local.use_api_key_auth ? 1 : 0
  role       = aws_iam_role.lambda_authorizer[0].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy" "lambda_authorizer_permissions" {
  count = var.create_iam_roles && local.use_api_key_auth ? 1 : 0
  name  = "${local.resource_prefix}-lambda-authorizer-policy"
  role  = aws_iam_role.lambda_authorizer[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue"
        ]
        Resource = var.api_authorizer_secrets_arn
      }
    ]
  })
}

# IAM Role for API Gateway to invoke authorizer
resource "aws_iam_role" "api_gateway_authorizer_invocation" {
  count = var.create_iam_roles && local.use_api_key_auth ? 1 : 0
  name  = "${local.resource_prefix}-api-gateway-auth-invocation"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "apigateway.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = local.common_tags
}

resource "aws_iam_role_policy" "api_gateway_authorizer_invocation" {
  count = var.create_iam_roles && local.use_api_key_auth ? 1 : 0
  name  = "${local.resource_prefix}-api-gateway-auth-invocation"
  role  = aws_iam_role.api_gateway_authorizer_invocation[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "lambda:InvokeFunction"
        ]
        Resource = aws_lambda_function.authorizer[0].arn
      }
    ]
  })
}
