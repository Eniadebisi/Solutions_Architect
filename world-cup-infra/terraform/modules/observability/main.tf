resource "aws_cloudwatch_log_group" "flow_logs" {
  name              = "/aws/vpc/${var.project_name}/flow-logs"
  retention_in_days = 7

  tags = {
    Name    = "${var.project_name}-flow-logs"
    Project = var.project_name
  }
}

# Reuse world-cup-dev instead of creating a new role.
# world-cup-dev's trust policy must include vpc-flow-logs.amazonaws.com —
# add this statement in the IAM console if flow logs aren't writing to CloudWatch:
#   Principal: { Service: "vpc-flow-logs.amazonaws.com" }
#   Action: sts:AssumeRole
data "aws_iam_role" "flow_logs" {
  name = "${var.project_name}-dev"
}

resource "aws_iam_role_policy" "flow_logs" {
  name = "${var.project_name}-vpc-flow-logs-policy"
  role = data.aws_iam_role.flow_logs.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents",
        "logs:DescribeLogGroups",
        "logs:DescribeLogStreams",
      ]
      Resource = "*"
    }]
  })
}

resource "aws_flow_log" "main" {
  iam_role_arn    = data.aws_iam_role.flow_logs.arn
  log_destination = aws_cloudwatch_log_group.flow_logs.arn
  traffic_type    = "ALL"
  vpc_id          = var.vpc_id

  tags = {
    Name    = "${var.project_name}-flow-logs"
    Project = var.project_name
  }
}
