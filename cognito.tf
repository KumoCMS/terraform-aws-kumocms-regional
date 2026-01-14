# Copyright (c) KumoCMS Contributors
# SPDX-License-Identifier: MIT

# ==================== Cognito User Pool ====================
# Optional AWS Cognito User Pool for JWT-based authentication
# Includes user pool, app client, and optional hosted UI domain
# Only created when create_cognito_user_pool = true

resource "aws_cognito_user_pool" "main" {
  count = var.create_cognito_user_pool ? 1 : 0
  name  = "${local.resource_prefix}-user-pool"

  # Password policy
  password_policy {
    minimum_length                   = var.cognito_password_min_length
    require_lowercase                = true
    require_uppercase                = true
    require_numbers                  = true
    require_symbols                  = true
    temporary_password_validity_days = 7
  }

  # User attributes
  schema {
    name                = "email"
    attribute_data_type = "String"
    required            = true
    mutable             = true

    string_attribute_constraints {
      min_length = 0
      max_length = 2048
    }
  }

  # Auto-verified attributes
  auto_verified_attributes = ["email"]

  # Email configuration
  email_configuration {
    email_sending_account = "COGNITO_DEFAULT"
  }

  # Account recovery
  account_recovery_setting {
    recovery_mechanism {
      name     = "verified_email"
      priority = 1
    }
  }

  # MFA configuration
  mfa_configuration = var.cognito_mfa_configuration

  # TOTP-based MFA configuration (required when mfa_configuration is not OFF)
  software_token_mfa_configuration {
    enabled = var.cognito_mfa_configuration != "OFF"
  }

  # Enable advanced security features
  user_pool_add_ons {
    advanced_security_mode = "ENFORCED"
  }

  # Deletion protection
  deletion_protection = var.cognito_deletion_protection ? "ACTIVE" : "INACTIVE"

  tags = local.common_tags
}

# ==================== Cognito User Pool Client ====================

resource "aws_cognito_user_pool_client" "main" {
  count        = var.create_cognito_user_pool ? 1 : 0
  name         = "${local.resource_prefix}-app-client"
  user_pool_id = aws_cognito_user_pool.main[0].id

  # Token validity
  access_token_validity  = 60  # minutes
  id_token_validity      = 60  # minutes
  refresh_token_validity = 30  # days

  token_validity_units {
    access_token  = "minutes"
    id_token      = "minutes"
    refresh_token = "days"
  }

  # OAuth flows
  allowed_oauth_flows_user_pool_client = true
  allowed_oauth_flows                  = ["code", "implicit"]
  allowed_oauth_scopes                 = ["email", "openid", "profile"]
  
  # Callback URLs (customize as needed)
  callback_urls = var.cognito_callback_urls
  logout_urls   = var.cognito_logout_urls

  # Supported identity providers
  supported_identity_providers = ["COGNITO"]

  # Prevent user existence errors
  prevent_user_existence_errors = "ENABLED"

  # Read and write attributes
  read_attributes = [
    "email",
    "email_verified",
  ]

  write_attributes = [
    "email",
  ]

  # Enable token revocation
  enable_token_revocation = true

  # Auth flows
  explicit_auth_flows = [
    "ALLOW_REFRESH_TOKEN_AUTH",
    "ALLOW_USER_SRP_AUTH",
    "ALLOW_USER_PASSWORD_AUTH"
  ]
}

# ==================== Cognito User Pool Domain ====================

resource "aws_cognito_user_pool_domain" "main" {
  count        = var.create_cognito_user_pool && var.cognito_domain_prefix != null ? 1 : 0
  domain       = var.cognito_domain_prefix
  user_pool_id = aws_cognito_user_pool.main[0].id
}
