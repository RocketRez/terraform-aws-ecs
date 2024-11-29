resource "aws_cloudwatch_log_group" "log_group" {
  name = "${var.project_name}-${var.service_name}"
  tags = var.tags
}


data "aws_iam_policy_document" "exec_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]
    effect  = "Allow"
    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}


locals {
  default_execution_permissions = [{
    actions = [
      "ecr:BatchCheckLayerAvailability",
      "ecr:GetDownloadUrlForLayer",
      "ecr:BatchGetImage"
    ],
    resources = [var.ecr_repo_arn]
    effect    = "Allow"
    },
    {
      actions   = ["ecr:GetAuthorizationToken"]
      resources = ["*"]
      effect    = "Allow"
    },
    {
      actions = [
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ],
      resources = ["${aws_cloudwatch_log_group.log_group.arn}:*"]
      effect    = "Allow"
  }]
  secrets_iam_permissions = [{
    actions = [
      "ssm:DescribeParameters",
      "ssm:GetParameters",
      "ssm:GetParameter",
      "ssm:GetParameterHistory"
    ]
    resources = [for secret in var.secrets : secret.valueFrom]
    effect    = "Allow"
  }]

  execution_role_iam_permissions_temp = length(var.execution_role_iam_permissions) != 0 ? var.execution_role_iam_permissions : tolist(local.default_execution_permissions)
  execution_role_iam_permissions      = concat(local.secrets_iam_permissions, local.execution_role_iam_permissions_temp)
}


data "aws_iam_policy_document" "exec_task_policy" {
  dynamic "statement" {
    for_each = local.execution_role_iam_permissions
    content {
      effect    = statement.value["effect"]
      actions   = statement.value["actions"]
      resources = statement.value["resources"]
    }
  }
}

resource "aws_iam_role" "execution_role" {
  name               = "${var.project_name}-${var.service_name}-execution-role-default"
  assume_role_policy = data.aws_iam_policy_document.exec_assume_role_policy.json
  path               = "/ci-cd-automated-roles/"
}

resource "aws_iam_role_policy" "exec_policy" {
  name   = "${var.project_name}-${var.service_name}-execution-role-policy-default"
  role   = aws_iam_role.execution_role.id
  policy = data.aws_iam_policy_document.exec_task_policy.json
}
