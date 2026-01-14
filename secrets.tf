# Secrets Manager for API authorizer
# Created only when deploying a private API (local.is_private_api == true)

# Generate a random API key
resource "random_password" "api_key" {
  count   = local.is_private_api ? 1 : 0
  length  = 32
  special = true
}

resource "aws_secretsmanager_secret" "api_authorizer" {
  count       = local.is_private_api ? 1 : 0
  name        = "${local.resource_prefix}-api-authorizer-secrets"
  description = "API authorization secrets for ${local.resource_prefix}"

  tags = local.common_tags
}

# Store the generated API key in the secret
resource "aws_secretsmanager_secret_version" "api_authorizer" {
  count     = local.is_private_api ? 1 : 0
  secret_id = aws_secretsmanager_secret.api_authorizer[0].id
  secret_string = jsonencode({
    api_keys = [random_password.api_key[0].result]
  })
}