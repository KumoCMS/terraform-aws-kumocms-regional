# Copyright (c) KumoCMS Contributors
# SPDX-License-Identifier: MIT

# ==================== SQS Dead Letter Queue ====================
# Dead Letter Queue for failed Lambda invocations
# 14-day message retention for debugging and recovery
# Only created when enable_dlq = true

resource "aws_sqs_queue" "dlq" {
  count                     = var.enable_dlq ? 1 : 0
  name                      = "${local.resource_prefix}-lambda-dlq"
  message_retention_seconds = 1209600 # 14 days

  tags = merge(
    local.common_tags,
    {
      Name = "${local.resource_prefix}-lambda-dlq"
    }
  )
}
