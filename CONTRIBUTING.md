# Contributing to KumoCMS Terraform Module

Thank you for your interest in contributing to the KumoCMS Terraform module! We welcome contributions from the community.

## Table of Contents

- [Code of Conduct](#code-of-conduct)
- [How to Contribute](#how-to-contribute)
- [Development Setup](#development-setup)
- [Coding Standards](#coding-standards)
- [Submitting Changes](#submitting-changes)
- [Reporting Issues](#reporting-issues)

## Code of Conduct

This project adheres to a [Code of Conduct](CODE_OF_CONDUCT.md). By participating, you are expected to uphold this code.

## How to Contribute

### Types of Contributions

- **Bug Reports**: Report issues with the module
- **Feature Requests**: Suggest new features or improvements
- **Documentation**: Improve README, examples, or inline documentation
- **Code**: Fix bugs or implement features

### Before You Start

1. Check existing [issues](https://github.com/kumocms/terraform-aws-kumocms-regional/issues) and [pull requests](https://github.com/kumocms/terraform-aws-kumocms-regional/pulls)
2. Open an issue to discuss major changes before implementing
3. Fork the repository and create a feature branch

## Development Setup

### Prerequisites

- Terraform >= 1.0
- AWS CLI configured with appropriate credentials
- Text editor with HCL/Terraform support

### Local Development

```bash
# Clone your fork
git clone https://github.com/YOUR_USERNAME/terraform-aws-kumocms-regional.git
cd terraform-aws-kumocms-regional

# Create a feature branch
git checkout -b feature/your-feature-name

# Make your changes
# ...

# Format Terraform code
terraform fmt -recursive

# Validate configuration
terraform init
terraform validate
```

## Coding Standards

### Terraform Style Guide

1. **Formatting**:
   - Use `terraform fmt` before committing
   - 2-space indentation
   - No trailing whitespace

2. **File Organization**:
   - Keep service-specific resources in separate files
   - Use descriptive file names (e.g., `s3.tf`, `lambda.tf`)
   - Group related resources together

3. **Naming Conventions**:
   - Resources: `${local.resource_prefix}-<descriptive-name>`
   - Variables: `snake_case`
   - Locals: `snake_case`
   - Use descriptive names that indicate purpose

4. **Comments**:
   - Add copyright header to all new .tf files
   - Use section headers with `# ========== Section Name ==========`
   - Comment complex logic and non-obvious decisions
   - Explain why, not just what

5. **Variables**:
   - Always include `description`
   - Provide `default` for optional variables
   - Add `validation` rules for critical inputs
   - Group related variables together

6. **Conditional Resources**:
   - Use `count` for conditional creation
   - Document conditions in comments
   - Update `locals.tf` for complex conditional logic

### Example Code Style

```hcl
# Copyright (c) KumoCMS Contributors
# SPDX-License-Identifier: MIT

# ==================== Service Name ====================
# Brief description of what this service does
# Additional context if needed

resource "aws_example_resource" "name" {
  # Configuration in logical order
  name        = "${local.resource_prefix}-example"
  description = "Descriptive text"
  
  # Complex blocks
  configuration {
    setting = "value"
  }
  
  # Conditional blocks using dynamic
  dynamic "optional_block" {
    for_each = var.enable_feature ? [1] : []
    content {
      # ...
    }
  }
  
  # Tags at the end
  tags = merge(
    local.common_tags,
    {
      Name = "${local.resource_prefix}-example"
    }
  )
}
```

## Submitting Changes

### Pull Request Process

1. **Prepare Your Changes**:
   ```bash
   # Format code
   terraform fmt -recursive
   
   # Validate
   terraform validate
   
   # Update documentation
   # - README.md (if user-facing changes)
   # - Inline comments
   # - CHANGELOG.md (for significant changes)
   ```

2. **Commit Guidelines**:
   - Use clear, descriptive commit messages
   - Reference issue numbers when applicable
   - Keep commits focused and atomic
   
   ```
   feat: add support for Lambda reserved concurrency
   
   - Add reserved_concurrent_executions variable
   - Update lambda.tf to use the new variable
   - Add documentation and example
   
   Closes #123
   ```

3. **Open Pull Request**:
   - Provide clear description of changes
   - Reference related issues
   - Include test results or validation output
   - Update documentation as needed

4. **Code Review**:
   - Address reviewer feedback
   - Keep discussion professional and constructive
   - Be responsive to comments

### PR Title Conventions

Use conventional commit format:
- `feat:` New feature
- `fix:` Bug fix
- `docs:` Documentation changes
- `refactor:` Code refactoring
- `test:` Test updates
- `chore:` Maintenance tasks

Examples:
- `feat: add Cognito User Pool creation support`
- `fix: correct IAM policy for Lambda authorizer`
- `docs: update README with private API examples`

## Reporting Issues

### Bug Reports

Include:
- **Description**: Clear description of the issue
- **Steps to Reproduce**: Minimal example to reproduce
- **Expected Behavior**: What should happen
- **Actual Behavior**: What actually happens
- **Environment**: Terraform version, AWS provider version
- **Configuration**: Relevant variable values (redact sensitive data)
- **Error Messages**: Full error output

### Feature Requests

Include:
- **Use Case**: Why is this feature needed?
- **Proposed Solution**: How should it work?
- **Alternatives**: Other approaches considered
- **Impact**: How does this affect existing functionality?

## Testing

### Manual Testing

Test your changes with:
1. **Admin mode**: `create_iam_roles = true`
2. **Power user mode**: `create_iam_roles = false`
3. **Public API**: `api_gateway_endpoint_type = "REGIONAL"`
4. **Private API**: `api_gateway_endpoint_type = "PRIVATE"`
5. **API key auth**: `auth_method = "api_key"`
6. **Cognito auth**: `auth_method = "cognito"`

### Test Checklist

- [ ] Code formatted with `terraform fmt`
- [ ] Configuration validates with `terraform validate`
- [ ] Documentation updated (README.md, inline comments)
- [ ] Variables have descriptions and defaults
- [ ] Outputs documented
- [ ] Backwards compatible (or breaking change documented)
- [ ] Tested with multiple configurations
- [ ] Examples updated if needed

## Questions?

- Open an issue for questions about contributing
- Join community discussions (if available)
- Review existing code for patterns and conventions

## License

By contributing to KumoCMS Terraform Module, you agree that your contributions will be licensed under the MIT License.

---

Thank you for contributing to KumoCMS! 🎉
