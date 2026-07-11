data "aws_caller_identity" "current" {}

resource "aws_iam_openid_connect_provider" "github_actions" {
  url             = "https://token.actions.githubusercontent.com"
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = ["6938fd4d98bab03faadb97b34396831e3780aea1"]

  tags = {
    Project = var.project_name
  }
}

# Reuse the existing world-cup-dev role for all GitHub Actions workflows.
# The role's trust policy must be updated to allow GitHub OIDC — see below.
data "aws_iam_role" "main" {
  name = "${var.project_name}-dev"
}

# ECR push permissions attached to world-cup-dev for the app repo CI
resource "aws_iam_role_policy" "ecr_push" {
  name = "ecr-push"
  role = data.aws_iam_role.main.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "ecr:GetAuthorizationToken",
        "ecr:BatchCheckLayerAvailability",
        "ecr:PutImage",
        "ecr:InitiateLayerUpload",
        "ecr:UploadLayerPart",
        "ecr:CompleteLayerUpload",
        "ecr:BatchGetImage",
        "ecr:GetDownloadUrlForLayer",
      ]
      Resource = "*"
    }]
  })
}
