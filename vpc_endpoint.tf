# Copyright (c) KumoCMS Contributors
# SPDX-License-Identifier: MIT

# ==================== VPC Endpoint for Private API Gateway ====================
# Interface VPC endpoint for private API Gateway access within VPC
# Includes optional security group with HTTPS ingress from VPC CIDR
# Only created when api_gateway_endpoint_type is PRIVATE and create_vpc_endpoint is true

# Security Group for VPC Endpoint (optional, created if not provided)
resource "aws_security_group" "vpc_endpoint" {
  count       = local.create_sg_for_vpce ? 1 : 0
  name        = "${local.resource_prefix}-vpce-sg"
  description = "Security group for API Gateway VPC endpoint"
  vpc_id      = var.vpc_id

  ingress {
    description = "HTTPS from VPC"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [data.aws_vpc.selected[0].cidr_block]
  }

  egress {
    description = "Allow all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(
    local.common_tags,
    {
      Name = "${local.resource_prefix}-vpce-sg"
    }
  )
}

# Data source for VPC (when creating VPC endpoint)
data "aws_vpc" "selected" {
  count = local.is_private_api && var.create_vpc_endpoint ? 1 : 0
  id    = var.vpc_id
}

# VPC Endpoint for API Gateway
resource "aws_vpc_endpoint" "api_gateway" {
  count             = local.is_private_api && var.create_vpc_endpoint ? 1 : 0
  vpc_id            = var.vpc_id
  service_name      = "com.amazonaws.${var.aws_region}.execute-api"
  vpc_endpoint_type = "Interface"

  subnet_ids         = var.subnet_ids
  security_group_ids = local.create_sg_for_vpce ? [aws_security_group.vpc_endpoint[0].id] : var.security_group_ids

  private_dns_enabled = true

  tags = merge(
    local.common_tags,
    {
      Name = "${local.resource_prefix}-api-gateway-vpce"
    }
  )
}
