# Copyright (c) KumoCMS Contributors
# SPDX-License-Identifier: MIT

# ==================== S3 Bucket for Document Storage ====================
# Creates S3 bucket with versioning, encryption, and lifecycle policies
# for secure document storage with optional event notifications

resource "aws_s3_bucket" "documents" {
  bucket = var.s3_bucket_name

  tags = merge(
    local.common_tags,
    {
      Name = "${local.resource_prefix}-documents"
    }
  )
}

resource "aws_s3_bucket_versioning" "documents" {
  count  = var.enable_s3_versioning ? 1 : 0
  bucket = aws_s3_bucket.documents.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "documents" {
  bucket = aws_s3_bucket.documents.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "documents" {
  bucket = aws_s3_bucket.documents.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_lifecycle_configuration" "documents" {
  count  = length(var.s3_lifecycle_rules) > 0 ? 1 : 0
  bucket = aws_s3_bucket.documents.id

  dynamic "rule" {
    for_each = var.s3_lifecycle_rules
    content {
      id     = rule.value.id
      status = rule.value.enabled ? "Enabled" : "Disabled"

      filter {
        prefix = rule.value.prefix
      }

      expiration {
        days = rule.value.expiration_days
      }

      noncurrent_version_expiration {
        noncurrent_days = rule.value.noncurrent_version_expiration
      }
    }
  }
}

# Enable S3 Event Notifications to EventBridge
resource "aws_s3_bucket_notification" "documents" {
  count       = var.enable_eventbridge_metadata_extraction ? 1 : 0
  bucket      = aws_s3_bucket.documents.id
  eventbridge = true
}
