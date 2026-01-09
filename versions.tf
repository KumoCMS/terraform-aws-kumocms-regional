# Copyright (c) KumoCMS Contributors
# SPDX-License-Identifier: MIT

# Terraform version and provider requirements
# This module requires Terraform 1.0+ and AWS Provider 5.0+

terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
  }
}
