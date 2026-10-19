
data "aws_caller_identity" "current" {}

data "aws_partition" "current" {}

# GitHub Actions OIDC provider.
# If your AWS account already has this provider, import it into
# Terraform state rather than attempting to create a duplicate.

data "aws_iam_openid_connect_provider" "github" {
  url = "https://token.actions.githubusercontent.com"
}

data "aws_iam_policy_document" "github_assume_role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = ["arn:aws:iam::255945442255:oidc-provider/token.actions.githubusercontent.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:sub"
      values = [
        "repo:${var.github_owner}/${var.github_repository}:ref:refs/heads/${var.github_branch}"
      ]
    }
  }
}

resource "aws_iam_role" "github_actions" {
  name                 = var.role_name
  description          = "GitHub Actions OIDC role for AWS CDK deployments"
  assume_role_policy   = data.aws_iam_policy_document.github_assume_role.json
  max_session_duration = 3600

  tags = {
    ManagedBy = "Terraform"
    Purpose   = "GitHubActionsDeployment"
  }
}

# One deployment policy covering the requested services and CDK support.
data "aws_iam_policy_document" "deployment" {
  statement {
    sid    = "CloudFormation"
    effect = "Allow"
    actions = [
      "cloudformation:*"
    ]
    resources = ["*"]
  }

  statement {
    sid    = "Lambda"
    effect = "Allow"
    actions = [
      "lambda:*"
    ]
    resources = ["*"]
  }

  statement {
    sid    = "DynamoDB"
    effect = "Allow"
    actions = [
      "dynamodb:*"
    ]
    resources = ["*"]
  }

  statement {
    sid    = "ApiGateway"
    effect = "Allow"
    actions = [
      "apigateway:*"
    ]
    resources = ["*"]
  }

  statement {
    sid    = "WAFv2"
    effect = "Allow"
    actions = [
      "wafv2:*"
    ]
    resources = ["*"]
  }

  statement {
    sid    = "IAMForDeployment"
    effect = "Allow"
    actions = [
      "iam:GetRole",
      "iam:CreateRole",
      "iam:DeleteRole",
      "iam:UpdateRole",
      "iam:UpdateAssumeRolePolicy",
      "iam:TagRole",
      "iam:UntagRole",
      "iam:PutRolePolicy",
      "iam:GetRolePolicy",
      "iam:DeleteRolePolicy",
      "iam:AttachRolePolicy",
      "iam:DetachRolePolicy",
      "iam:ListRolePolicies",
      "iam:ListAttachedRolePolicies",
      "iam:PassRole",
      "iam:CreatePolicy",
      "iam:DeletePolicy",
      "iam:GetPolicy",
      "iam:GetPolicyVersion",
      "iam:CreatePolicyVersion",
      "iam:DeletePolicyVersion",
      "iam:ListPolicyVersions",
      "iam:TagPolicy",
      "iam:UntagPolicy",
      "iam:ListInstanceProfilesForRole"
    ]
    resources = ["*"]
  }

  statement {
    sid    = "CdkAssetsAndLogs"
    effect = "Allow"
    actions = [
      "s3:*",
      "ecr:*",
      "logs:*"
    ]
    resources = ["*"]
  }

  statement {
    sid    = "DeploymentIdentity"
    effect = "Allow"
    actions = [
      "sts:GetCallerIdentity",
      "sts:AssumeRole"
    ]
    resources = ["*"]
  }
}

resource "aws_iam_role_policy" "deployment" {
  name   = var.policy_name
  role   = aws_iam_role.github_actions.id
  policy = data.aws_iam_policy_document.deployment.json
}
