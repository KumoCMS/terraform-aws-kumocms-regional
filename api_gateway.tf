# Copyright (c) KumoCMS Contributors
# SPDX-License-Identifier: MIT

# ==================== API Gateway ====================
# REST API configuration with support for:
# - Public (REGIONAL) and Private (VPC) endpoints
# - Dual authentication (API Key via Lambda or AWS Cognito)
# - Specific endpoints for document operations
# - CORS support for web applications

resource "aws_api_gateway_rest_api" "main" {
  name        = "${local.resource_prefix}-api"
  description = "KumoCMS Regional API"

  endpoint_configuration {
    types            = [var.api_gateway_endpoint_type]
    vpc_endpoint_ids = local.is_private_api ? [local.vpc_endpoint_id] : null
  }

  tags = local.common_tags
}

# Resource policy for private API Gateway
resource "aws_api_gateway_rest_api_policy" "main" {
  count       = local.is_private_api ? 1 : 0
  rest_api_id = aws_api_gateway_rest_api.main.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = "*"
        Action    = "execute-api:Invoke"
        Resource  = "${aws_api_gateway_rest_api.main.execution_arn}/*"
        Condition = {
          StringEquals = {
            "aws:SourceVpce" = local.vpc_endpoint_id
          }
        }
      }
    ]
  })
}

# ==================== Authorizers ====================

# Custom API Key Authorizer (using Lambda)
resource "aws_api_gateway_authorizer" "api_key" {
  count                  = local.use_api_key_auth ? 1 : 0
  name                   = "${local.resource_prefix}-api-key-authorizer"
  rest_api_id            = aws_api_gateway_rest_api.main.id
  authorizer_uri         = aws_lambda_function.authorizer.invoke_arn
  authorizer_credentials = local.api_gateway_authorizer_invocation_role_arn
  type                   = "REQUEST"
  identity_source        = "method.request.header.Authorization"
}

# Cognito Authorizer
resource "aws_api_gateway_authorizer" "cognito" {
  count         = local.use_cognito_auth ? 1 : 0
  name          = "${local.resource_prefix}-cognito-authorizer"
  rest_api_id   = aws_api_gateway_rest_api.main.id
  type          = "COGNITO_USER_POOLS"
  provider_arns = [local.cognito_user_pool_arn]
  identity_source = "method.request.header.Authorization"
}

# ==================== API Resources ====================

# /healthcheck resource (no authorization)
resource "aws_api_gateway_resource" "healthcheck" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  parent_id   = aws_api_gateway_rest_api.main.root_resource_id
  path_part   = "healthcheck"
}

resource "aws_api_gateway_method" "healthcheck_get" {
  rest_api_id   = aws_api_gateway_rest_api.main.id
  resource_id   = aws_api_gateway_resource.healthcheck.id
  http_method   = "GET"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "healthcheck_get" {
  rest_api_id             = aws_api_gateway_rest_api.main.id
  resource_id             = aws_api_gateway_resource.healthcheck.id
  http_method             = aws_api_gateway_method.healthcheck_get.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.api_handler.invoke_arn
}

# /documents resource
resource "aws_api_gateway_resource" "documents" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  parent_id   = aws_api_gateway_rest_api.main.root_resource_id
  path_part   = "documents"
}

# GET /documents (list documents)
resource "aws_api_gateway_method" "documents_get" {
  rest_api_id   = aws_api_gateway_rest_api.main.id
  resource_id   = aws_api_gateway_resource.documents.id
  http_method   = "GET"
  authorization = local.use_cognito_auth ? "COGNITO_USER_POOLS" : "CUSTOM"
  authorizer_id = local.authorizer_id
}

resource "aws_api_gateway_integration" "documents_get" {
  rest_api_id             = aws_api_gateway_rest_api.main.id
  resource_id             = aws_api_gateway_resource.documents.id
  http_method             = aws_api_gateway_method.documents_get.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.api_handler.invoke_arn
}

# POST /documents (upload)
resource "aws_api_gateway_method" "documents_post" {
  rest_api_id   = aws_api_gateway_rest_api.main.id
  resource_id   = aws_api_gateway_resource.documents.id
  http_method   = "POST"
  authorization = local.use_cognito_auth ? "COGNITO_USER_POOLS" : "CUSTOM"
  authorizer_id = local.authorizer_id
}

resource "aws_api_gateway_integration" "documents_post" {
  rest_api_id             = aws_api_gateway_rest_api.main.id
  resource_id             = aws_api_gateway_resource.documents.id
  http_method             = aws_api_gateway_method.documents_post.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.api_handler.invoke_arn
}

# /documents/{id} resource
resource "aws_api_gateway_resource" "document_id" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  parent_id   = aws_api_gateway_resource.documents.id
  path_part   = "{id}"
}

# GET /documents/{id} (retrieve/download)
resource "aws_api_gateway_method" "document_id_get" {
  rest_api_id   = aws_api_gateway_rest_api.main.id
  resource_id   = aws_api_gateway_resource.document_id.id
  http_method   = "GET"
  authorization = local.use_cognito_auth ? "COGNITO_USER_POOLS" : "CUSTOM"
  authorizer_id = local.authorizer_id

  request_parameters = {
    "method.request.path.id" = true
  }
}

resource "aws_api_gateway_integration" "document_id_get" {
  rest_api_id             = aws_api_gateway_rest_api.main.id
  resource_id             = aws_api_gateway_resource.document_id.id
  http_method             = aws_api_gateway_method.document_id_get.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.api_handler.invoke_arn
}

# PUT /documents/{id} (replace)
resource "aws_api_gateway_method" "document_id_put" {
  rest_api_id   = aws_api_gateway_rest_api.main.id
  resource_id   = aws_api_gateway_resource.document_id.id
  http_method   = "PUT"
  authorization = local.use_cognito_auth ? "COGNITO_USER_POOLS" : "CUSTOM"
  authorizer_id = local.authorizer_id

  request_parameters = {
    "method.request.path.id" = true
  }
}

resource "aws_api_gateway_integration" "document_id_put" {
  rest_api_id             = aws_api_gateway_rest_api.main.id
  resource_id             = aws_api_gateway_resource.document_id.id
  http_method             = aws_api_gateway_method.document_id_put.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.api_handler.invoke_arn
}

# DELETE /documents/{id}
resource "aws_api_gateway_method" "document_id_delete" {
  rest_api_id   = aws_api_gateway_rest_api.main.id
  resource_id   = aws_api_gateway_resource.document_id.id
  http_method   = "DELETE"
  authorization = local.use_cognito_auth ? "COGNITO_USER_POOLS" : "CUSTOM"
  authorizer_id = local.authorizer_id

  request_parameters = {
    "method.request.path.id" = true
  }
}

resource "aws_api_gateway_integration" "document_id_delete" {
  rest_api_id             = aws_api_gateway_rest_api.main.id
  resource_id             = aws_api_gateway_resource.document_id.id
  http_method             = aws_api_gateway_method.document_id_delete.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.api_handler.invoke_arn
}

# /documents/{id}/archive resource
resource "aws_api_gateway_resource" "document_archive" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  parent_id   = aws_api_gateway_resource.document_id.id
  path_part   = "archive"
}

# POST /documents/{id}/archive
resource "aws_api_gateway_method" "document_archive_post" {
  rest_api_id   = aws_api_gateway_rest_api.main.id
  resource_id   = aws_api_gateway_resource.document_archive.id
  http_method   = "POST"
  authorization = local.use_cognito_auth ? "COGNITO_USER_POOLS" : "CUSTOM"
  authorizer_id = local.authorizer_id

  request_parameters = {
    "method.request.path.id" = true
  }
}

resource "aws_api_gateway_integration" "document_archive_post" {
  rest_api_id             = aws_api_gateway_rest_api.main.id
  resource_id             = aws_api_gateway_resource.document_archive.id
  http_method             = aws_api_gateway_method.document_archive_post.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.api_handler.invoke_arn
}

# /documents/{id}/restore resource
resource "aws_api_gateway_resource" "document_restore" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  parent_id   = aws_api_gateway_resource.document_id.id
  path_part   = "restore"
}

# POST /documents/{id}/restore
resource "aws_api_gateway_method" "document_restore_post" {
  rest_api_id   = aws_api_gateway_rest_api.main.id
  resource_id   = aws_api_gateway_resource.document_restore.id
  http_method   = "POST"
  authorization = local.use_cognito_auth ? "COGNITO_USER_POOLS" : "CUSTOM"
  authorizer_id = local.authorizer_id

  request_parameters = {
    "method.request.path.id" = true
  }
}

resource "aws_api_gateway_integration" "document_restore_post" {
  rest_api_id             = aws_api_gateway_rest_api.main.id
  resource_id             = aws_api_gateway_resource.document_restore.id
  http_method             = aws_api_gateway_method.document_restore_post.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.api_handler.invoke_arn
}

# ==================== CORS Support ====================

# OPTIONS for /documents
resource "aws_api_gateway_method" "documents_options" {
  rest_api_id   = aws_api_gateway_rest_api.main.id
  resource_id   = aws_api_gateway_resource.documents.id
  http_method   = "OPTIONS"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "documents_options" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  resource_id = aws_api_gateway_resource.documents.id
  http_method = aws_api_gateway_method.documents_options.http_method
  type        = "MOCK"

  request_templates = {
    "application/json" = "{\"statusCode\": 200}"
  }
}

resource "aws_api_gateway_method_response" "documents_options" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  resource_id = aws_api_gateway_resource.documents.id
  http_method = aws_api_gateway_method.documents_options.http_method
  status_code = "200"

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = true
    "method.response.header.Access-Control-Allow-Methods" = true
    "method.response.header.Access-Control-Allow-Origin"  = true
  }

  response_models = {
    "application/json" = "Empty"
  }
}

resource "aws_api_gateway_integration_response" "documents_options" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  resource_id = aws_api_gateway_resource.documents.id
  http_method = aws_api_gateway_method.documents_options.http_method
  status_code = aws_api_gateway_method_response.documents_options.status_code

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = "'Content-Type,Authorization'"
    "method.response.header.Access-Control-Allow-Methods" = "'GET,POST,OPTIONS'"
    "method.response.header.Access-Control-Allow-Origin"  = "'*'"
  }

  depends_on = [aws_api_gateway_integration.documents_options]
}

# OPTIONS for /documents/{id}
resource "aws_api_gateway_method" "document_id_options" {
  rest_api_id   = aws_api_gateway_rest_api.main.id
  resource_id   = aws_api_gateway_resource.document_id.id
  http_method   = "OPTIONS"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "document_id_options" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  resource_id = aws_api_gateway_resource.document_id.id
  http_method = aws_api_gateway_method.document_id_options.http_method
  type        = "MOCK"

  request_templates = {
    "application/json" = "{\"statusCode\": 200}"
  }
}

resource "aws_api_gateway_method_response" "document_id_options" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  resource_id = aws_api_gateway_resource.document_id.id
  http_method = aws_api_gateway_method.document_id_options.http_method
  status_code = "200"

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = true
    "method.response.header.Access-Control-Allow-Methods" = true
    "method.response.header.Access-Control-Allow-Origin"  = true
  }

  response_models = {
    "application/json" = "Empty"
  }
}

resource "aws_api_gateway_integration_response" "document_id_options" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  resource_id = aws_api_gateway_resource.document_id.id
  http_method = aws_api_gateway_method.document_id_options.http_method
  status_code = aws_api_gateway_method_response.document_id_options.status_code

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = "'Content-Type,Authorization'"
    "method.response.header.Access-Control-Allow-Methods" = "'GET,PUT,DELETE,OPTIONS'"
    "method.response.header.Access-Control-Allow-Origin"  = "'*'"
  }

  depends_on = [aws_api_gateway_integration.document_id_options]
}

# OPTIONS for /documents/{id}/archive
resource "aws_api_gateway_method" "document_archive_options" {
  rest_api_id   = aws_api_gateway_rest_api.main.id
  resource_id   = aws_api_gateway_resource.document_archive.id
  http_method   = "OPTIONS"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "document_archive_options" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  resource_id = aws_api_gateway_resource.document_archive.id
  http_method = aws_api_gateway_method.document_archive_options.http_method
  type        = "MOCK"

  request_templates = {
    "application/json" = "{\"statusCode\": 200}"
  }
}

resource "aws_api_gateway_method_response" "document_archive_options" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  resource_id = aws_api_gateway_resource.document_archive.id
  http_method = aws_api_gateway_method.document_archive_options.http_method
  status_code = "200"

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = true
    "method.response.header.Access-Control-Allow-Methods" = true
    "method.response.header.Access-Control-Allow-Origin"  = true
  }

  response_models = {
    "application/json" = "Empty"
  }
}

resource "aws_api_gateway_integration_response" "document_archive_options" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  resource_id = aws_api_gateway_resource.document_archive.id
  http_method = aws_api_gateway_method.document_archive_options.http_method
  status_code = aws_api_gateway_method_response.document_archive_options.status_code

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = "'Content-Type,Authorization'"
    "method.response.header.Access-Control-Allow-Methods" = "'POST,OPTIONS'"
    "method.response.header.Access-Control-Allow-Origin"  = "'*'"
  }

  depends_on = [aws_api_gateway_integration.document_archive_options]
}

# OPTIONS for /documents/{id}/restore
resource "aws_api_gateway_method" "document_restore_options" {
  rest_api_id   = aws_api_gateway_rest_api.main.id
  resource_id   = aws_api_gateway_resource.document_restore.id
  http_method   = "OPTIONS"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "document_restore_options" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  resource_id = aws_api_gateway_resource.document_restore.id
  http_method = aws_api_gateway_method.document_restore_options.http_method
  type        = "MOCK"

  request_templates = {
    "application/json" = "{\"statusCode\": 200}"
  }
}

resource "aws_api_gateway_method_response" "document_restore_options" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  resource_id = aws_api_gateway_resource.document_restore.id
  http_method = aws_api_gateway_method.document_restore_options.http_method
  status_code = "200"

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = true
    "method.response.header.Access-Control-Allow-Methods" = true
    "method.response.header.Access-Control-Allow-Origin"  = true
  }

  response_models = {
    "application/json" = "Empty"
  }
}

resource "aws_api_gateway_integration_response" "document_restore_options" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  resource_id = aws_api_gateway_resource.document_restore.id
  http_method = aws_api_gateway_method.document_restore_options.http_method
  status_code = aws_api_gateway_method_response.document_restore_options.status_code

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = "'Content-Type,Authorization'"
    "method.response.header.Access-Control-Allow-Methods" = "'POST,OPTIONS'"
    "method.response.header.Access-Control-Allow-Origin"  = "'*'"
  }

  depends_on = [aws_api_gateway_integration.document_restore_options]
}

# ==================== Deployment ====================

# Root resource proxy
resource "aws_api_gateway_resource" "proxy" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  parent_id   = aws_api_gateway_rest_api.main.root_resource_id
  path_part   = "{proxy+}"
}

# Proxy method with authorizer
resource "aws_api_gateway_method" "proxy" {
  rest_api_id   = aws_api_gateway_rest_api.main.id
  resource_id   = aws_api_gateway_resource.proxy.id
  http_method   = "ANY"
  authorization = local.use_cognito_auth ? "COGNITO_USER_POOLS" : "CUSTOM"
  authorizer_id = local.authorizer_id

  request_parameters = {
    "method.request.path.proxy" = true
  }
}

# Lambda integration
resource "aws_api_gateway_integration" "lambda" {
  rest_api_id             = aws_api_gateway_rest_api.main.id
  resource_id             = aws_api_gateway_resource.proxy.id
  http_method             = aws_api_gateway_method.proxy.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.api_handler.invoke_arn
}

# API Gateway Deployment
resource "aws_api_gateway_deployment" "main" {
  rest_api_id = aws_api_gateway_rest_api.main.id

  triggers = {
    redeployment = sha1(jsonencode([
      aws_api_gateway_resource.healthcheck.id,
      aws_api_gateway_resource.documents.id,
      aws_api_gateway_resource.document_id.id,
      aws_api_gateway_resource.document_archive.id,
      aws_api_gateway_resource.document_restore.id,
      aws_api_gateway_method.healthcheck_get.id,
      aws_api_gateway_method.documents_get.id,
      aws_api_gateway_method.documents_post.id,
      aws_api_gateway_method.document_id_get.id,
      aws_api_gateway_method.document_id_put.id,
      aws_api_gateway_method.document_id_delete.id,
      aws_api_gateway_method.document_archive_post.id,
      aws_api_gateway_method.document_restore_post.id,
      aws_api_gateway_integration.healthcheck_get.id,
      aws_api_gateway_integration.documents_get.id,
      aws_api_gateway_integration.documents_post.id,
      aws_api_gateway_integration.document_id_get.id,
      aws_api_gateway_integration.document_id_put.id,
      aws_api_gateway_integration.document_id_delete.id,
      aws_api_gateway_integration.document_archive_post.id,
      aws_api_gateway_integration.document_restore_post.id,
    ]))
  }

  lifecycle {
    create_before_destroy = true
  }

  depends_on = [
    aws_api_gateway_integration.healthcheck_get,
    aws_api_gateway_integration.documents_get,
    aws_api_gateway_integration.documents_post,
    aws_api_gateway_integration.document_id_get,
    aws_api_gateway_integration.document_id_put,
    aws_api_gateway_integration.document_id_delete,
    aws_api_gateway_integration.document_archive_post,
    aws_api_gateway_integration.document_restore_post,
    aws_api_gateway_integration.lambda
  ]
}

# API Gateway Stage
resource "aws_api_gateway_stage" "main" {
  deployment_id = aws_api_gateway_deployment.main.id
  rest_api_id   = aws_api_gateway_rest_api.main.id
  stage_name    = var.api_gateway_stage_name

  tags = local.common_tags
}

# API Gateway Method Settings
resource "aws_api_gateway_method_settings" "main" {
  count       = var.enable_api_gateway_logs ? 1 : 0
  rest_api_id = aws_api_gateway_rest_api.main.id
  stage_name  = aws_api_gateway_stage.main.stage_name
  method_path = "*/*"

  settings {
    logging_level      = "INFO"
    data_trace_enabled = true
    metrics_enabled    = true
  }
}
