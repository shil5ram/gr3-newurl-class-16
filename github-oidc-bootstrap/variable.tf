variable "aws_region" {
  description = "The AWS region to deploy resources in."
  type        = string
  default     = "us-east-1"
}
variable "github_owner" {
  description = "The GitHub organization or user that owns the repository."
  type        = string
}
variable "github_repository" {
  description = "The GitHub repository name."
  type        = string
}
variable "github_branch" {
  description = "The GitHub branch to use for the OIDC trust relationship."
  type        = string
  default     = "main"
}

variable "role_name" {
  description = "IAM role name for GitHub Actions"
  type        = string
  default     = "github-actions-aws-deploy"
}

variable "policy_name" {
  description = "Deployment policy name"
  type        = string
  default     = "github-actions-aws-deploy-policy"
}