# Copyright (c) KumoCMS Contributors
# SPDX-License-Identifier: MIT

# ==================== DynamoDB Global Table ====================
# DynamoDB global table for document metadata storage
# Supports conditional creation based on create_dynamodb_table variable
# Includes stream for EventBridge integration and global replication capability

resource "aws_dynamodb_table" "metadata" {
  count            = var.create_dynamodb_table ? 1 : 0
  name             = var.dynamodb_table_name
  billing_mode     = "PAY_PER_REQUEST"
  hash_key         = "PK"
  range_key        = "SK"
  stream_enabled   = true
  stream_view_type = "NEW_AND_OLD_IMAGES"

  attribute {
    name = "PK"
    type = "S"
  }

  attribute {
    name = "SK"
    type = "S"
  }

  # Global Secondary Index for querying by document type
  attribute {
    name = "documentType"
    type = "S"
  }

  attribute {
    name = "uploadedAt"
    type = "S"
  }

  global_secondary_index {
    name            = "DocumentTypeIndex"
    hash_key        = "documentType"
    range_key       = "uploadedAt"
    projection_type = "ALL"
  }

  # Point-in-time recovery for data protection
  point_in_time_recovery {
    enabled = true
  }

  # Server-side encryption
  server_side_encryption {
    enabled = true
  }

  # Replica configuration for global table
  # Primary replica is in the specified AWS region
  replica {
    region_name = var.aws_region
  }

  tags = merge(
    local.common_tags,
    {
      Name = var.dynamodb_table_name
    }
  )
}
