data "aws_iam_policy_document" "ecs_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]
    effect  = "Allow"
    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}



data "aws_iam_policy_document" "ecs_task_policy" {
  dynamic "statement" {
    for_each = var.service_iam_permissions
    content {
      effect    = statement.value["effect"]
      actions   = statement.value["actions"]
      resources = statement.value["resources"]
    }
  }
}

resource "aws_iam_role" "ecs_role" {
  name               = "${var.project_name}-${var.service_name}-ecs-role-default"
  assume_role_policy = data.aws_iam_policy_document.ecs_assume_role_policy.json
  path               = "/ci-cd-automated-roles/"
}

resource "aws_iam_role_policy" "policy" {
  name   = "${var.project_name}-${var.service_name}-role-policy-default"
  role   = aws_iam_role.ecs_role.id
  policy = data.aws_iam_policy_document.ecs_task_policy.json
}

locals {
  task_role_arn      = var.task_role_arn != "" ? var.task_role_arn : aws_iam_role.ecs_role.arn
  execution_role_arn = var.execution_role_arn != "" ? var.execution_role_arn : aws_iam_role.execution_role.arn
}

resource "aws_ecs_task_definition" "task" {
  family                   = "${var.project_name}-${var.service_name}"
  container_definitions    = jsonencode(var.container_definitions)
  cpu                      = var.cpu
  memory                   = var.memory
  requires_compatibilities = var.requires_compatibilities
  task_role_arn            = local.task_role_arn
  network_mode             = var.network_mode
  execution_role_arn       = local.execution_role_arn
}
