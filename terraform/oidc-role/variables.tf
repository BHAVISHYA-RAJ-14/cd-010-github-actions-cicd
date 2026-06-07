# terraform/oidc-role/variables.tf

variable "aws_region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "ap-south-1"
}

variable "github_org" {
  description = "GitHub organization or username"
  type        = string
}

variable "github_repo" {
  description = "GitHub repository name"
  type        = string
}

variable "project_name" {
  description = "Project name for tagging"
  type        = string
  default     = "cd-010-github-actions-cicd"
}
