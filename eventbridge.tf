# Copyright (c) KumoCMS Contributors
# SPDX-License-Identifier: MIT

# ==================== EventBridge Rules ====================
# Optional event-driven metadata extraction on document upload
# Triggers Lambda function when new objects are created in S3
# Only created when enable_eventbridge_metadata_extraction = true

resource "aws_cloudwatch_event_rule" "metadata_extraction" {
  count       = var.enable_eventbridge_metadata_extraction ? 1 : 0
  name        = "${local.resource_prefix}-metadata-extraction"
  description = "Trigger metadata extraction when documents are uploaded"

  event_pattern = jsonencode({
    source      = ["aws.s3"]
    detail-type = ["Object Created"]
    detail = {
      bucket = {
        name = [aws_s3_bucket.documents.id]
      }
    }
  })

  tags = local.common_tags
}

resource "aws_cloudwatch_event_target" "metadata_extraction" {
  count     = var.enable_eventbridge_metadata_extraction ? 1 : 0
  rule      = aws_cloudwatch_event_rule.metadata_extraction[0].name
  target_id = "MetadataExtractionLambda"
  arn       = aws_lambda_function.event_processor[0].arn
}
