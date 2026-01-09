# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- Initial release of terraform-aws-kumocms-regional module
- Support for S3-based document storage with versioning and encryption
- Lambda functions for API handling, authentication, and event processing
- REST API via API Gateway with public and private endpoint support
- Dual authentication: API Key (Lambda authorizer) and AWS Cognito
- Optional Cognito User Pool creation with configurable security settings
- Admin and power user deployment modes for flexible IAM management
- VPC endpoint support for private API Gateway access
- Optional EventBridge-driven metadata extraction
- Dead Letter Queue for failed Lambda invocations
- CloudWatch Logs with 14-day retention
- Optional WAF association for API protection
- CORS support for all authenticated endpoints
- Comprehensive documentation with multiple deployment examples

### Security
- S3 public access blocked by default
- Server-side encryption enabled (AES256)
- Least-privilege IAM roles for all Lambda functions
- Cognito User Pool with advanced security mode enforced
- Deletion protection for Cognito User Pools

## [1.0.0] - YYYY-MM-DD

### Added
- First stable release

[Unreleased]: https://github.com/kumocms/terraform-aws-kumocms-regional/compare/v1.0.0...HEAD
[1.0.0]: https://github.com/kumocms/terraform-aws-kumocms-regional/releases/tag/v1.0.0
