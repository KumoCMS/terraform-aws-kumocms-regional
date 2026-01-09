# Copyright (c) KumoCMS Contributors
# SPDX-License-Identifier: MIT

# ==================== WAF Association ====================
# Optional AWS WAF Web ACL association for API Gateway protection
# Provides rate limiting, IP filtering, and threat detection
# Only created when enable_waf = true

resource "aws_wafv2_web_acl_association" "api_gateway" {
  count        = var.enable_waf ? 1 : 0
  resource_arn = aws_api_gateway_stage.main.arn
  web_acl_arn  = var.waf_web_acl_arn
}
