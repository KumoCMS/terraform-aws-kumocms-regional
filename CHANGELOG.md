## [1.3.3](https://github.com/KumoCMS/terraform-aws-kumocms-regional/compare/v1.3.2...v1.3.3) (2026-01-14)


### Bug Fixes

* errors for v1.3.3 ([#7](https://github.com/KumoCMS/terraform-aws-kumocms-regional/issues/7)) ([d8d65c2](https://github.com/KumoCMS/terraform-aws-kumocms-regional/commit/d8d65c2447bf6900c598da94334e8912deba5a1f))

## [1.3.2](https://github.com/KumoCMS/terraform-aws-kumocms-regional/compare/v1.3.1...v1.3.2) (2026-01-14)


### Bug Fixes

* iam policy extra closing brace ([#6](https://github.com/KumoCMS/terraform-aws-kumocms-regional/issues/6)) ([d4d94bb](https://github.com/KumoCMS/terraform-aws-kumocms-regional/commit/d4d94bb60a0ec59a00420de8020c362fbe23664a))

## [1.3.1](https://github.com/KumoCMS/terraform-aws-kumocms-regional/compare/v1.3.0...v1.3.1) (2026-01-14)


### Bug Fixes

* iam policy error ([#5](https://github.com/KumoCMS/terraform-aws-kumocms-regional/issues/5)) ([0e10e15](https://github.com/KumoCMS/terraform-aws-kumocms-regional/commit/0e10e157a75fd10f29fd1128aa15d80e9fe479d0))

## [1.3.0](https://github.com/KumoCMS/terraform-aws-kumocms-regional/compare/v1.2.0...v1.3.0) (2026-01-14)


### Features

* dynamodb replica ([#4](https://github.com/KumoCMS/terraform-aws-kumocms-regional/issues/4)) ([3da28d8](https://github.com/KumoCMS/terraform-aws-kumocms-regional/commit/3da28d870b7a57792dbcdd0abb6ea5c169120d80))

## [1.2.0](https://github.com/KumoCMS/terraform-aws-kumocms-regional/compare/v1.1.1...v1.2.0) (2026-01-14)


### Features

* mfa config ([e131ae7](https://github.com/KumoCMS/terraform-aws-kumocms-regional/commit/e131ae77493a01aa0401e247cc3066e6b92f8540))

## [1.1.1](https://github.com/KumoCMS/terraform-aws-kumocms-regional/compare/v1.1.0...v1.1.1) (2026-01-14)


### Bug Fixes

* api gateway ([d2a6ca3](https://github.com/KumoCMS/terraform-aws-kumocms-regional/commit/d2a6ca327a1d498ec1ff6ce53746a68bfd87e89f))

## [1.1.0](https://github.com/KumoCMS/terraform-aws-kumocms-regional/compare/v1.0.0...v1.1.0) (2026-01-14)


### Features

* add dynamodb ([530d0c5](https://github.com/KumoCMS/terraform-aws-kumocms-regional/commit/530d0c5b73b4a03c821ab752ccaa89431eade101))
* add secret manager ([1fa5370](https://github.com/KumoCMS/terraform-aws-kumocms-regional/commit/1fa5370dc0f6248ea40d37877fa5277839ac446f))

## 1.0.0 (2026-01-09)


### Features

* initial release ([e11f686](https://github.com/KumoCMS/terraform-aws-kumocms-regional/commit/e11f686d7298ef62061f4d44a514e608e90acee6))

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
