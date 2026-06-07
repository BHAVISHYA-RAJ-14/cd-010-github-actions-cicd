# terraform/oidc-role/outputs.tf

output "oidc_provider_arn" {
  description = "ARN of the OIDC provider"
  value       = aws_iam_openid_connect_provider.github.arn
}

output "github_role_arn_dev" {
  description = "ARN of the IAM role for Development"
  value       = aws_iam_role.github_dev.arn
}

output "github_role_arn_prod" {
  description = "ARN of the IAM role for Production"
  value       = aws_iam_role.github_prod.arn
}

output "setup_instructions" {
  description = "Instructions for GitHub Actions setup"
  value       = <<EOF
1. Go to your GitHub Repository Settings > Secrets and variables > Actions.
2. Add the following repository secrets:
   - AWS_ROLE_ARN_DEV:  ${aws_iam_role.github_dev.arn}
   - AWS_ROLE_ARN_PROD: ${aws_iam_role.github_prod.arn}
   - ECR_REGISTRY:      <YOUR_AWS_ACCOUNT_ID>.dkr.ecr.${var.aws_region}.amazonaws.com
EOF
}
