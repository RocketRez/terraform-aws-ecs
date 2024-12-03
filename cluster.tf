

resource "aws_ecs_cluster" "cluster" {
  count  = var.use_default_cluster ? 1 : 0
  name = var.project_name
  tags = var.tags
}


data "aws_ecs_cluster" "cluster_derived" {
  count  = var.use_default_cluster ?  0 : 1
  cluster_name = var.project_name
}

locals {
  aws_ecs_cluster = var.use_default_cluster ? aws_ecs_cluster.cluster : data.aws_ecs_cluster.cluster_derived
}
