locals {
  private_network_cidrs = ["10.0.0.0/8", "172.16.0.0/12", "192.168.0.0/16"]
  # derive specific dockerhub image to pull
  image_tag             = lookup(var.snyk_integration_images, var.integration_type, "")
  image                 = format("%s:%s", var.snykbroker_repo, local.image_tag)
  # merge with user specified terraform tags
  tags                  = merge({environment = "SnykBroker"}, var.tags)
  # environment variables key-value pairs
  env_vars              = lookup(var.snyk_integration_env_vars, var.integration_type, [])
  broker_port           = lookup(var.broker_env_vars, "PORT", var.default_broker_port)
  broker_env_vars       = merge({
    for v in local.env_vars:
      v => lookup(var.broker_env_vars, v, "")
  }, var.additional_env_vars)
}

data "aws_availability_zones" "available" {
  state = "available"
}

module "snykbroker_vpc" {
  source = "terraform-aws-modules/vpc/aws"
  version = "3.14.2"

  name = "snykbroker_vpc"
  cidr = "192.168.0.0/20"

  # select the first grouping of specified number of service_azs
  azs             = chunklist(data.aws_availability_zones.available.names, var.service_azs)[0]
  # each subnet on /24 prefix with 256 addresses
  private_subnets = [for x in range(var.service_azs) : cidrsubnet("192.168.0.0/21", 3, x)]
  public_subnets  = [for x in range(var.service_azs) : cidrsubnet("192.168.8.0/21", 3, x)]
  # One NAT Gateway per subnet (default)
  enable_nat_gateway   = true
  enable_dns_hostnames = false
  enable_dns_support   = true

  tags = local.tags
}

module "snykbroker_security_group" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "4.9.0"

  name        = "snykbroker_service"
  description = "Security group for SnykBroker with https and client port open within VPC"
  vpc_id      = module.snykbroker_vpc.vpc_id

  # allow ingress from private networks on customer premises
  ingress_cidr_blocks      = local.private_network_cidrs
  ingress_rules            = ["https-443-tcp"]
  ingress_with_cidr_blocks = [
    for cidr_block in local.private_network_cidrs :
      {
        from_port   = local.broker_port
        to_port     = local.broker_port
        protocol    = "tcp"
        description = "SnykBroker client port from private ${cidr_block}"
        cidr_blocks = cidr_block
      }
  ]
  egress_cidr_blocks      = ["0.0.0.0/0"]
  egress_rules            = ["https-443-tcp"]

  tags = local.tags
}

module "snyk_ecs_cluster" {
  source  = "terraform-aws-modules/ecs/aws"
  version = "4.1.1"

  cluster_name = "snykbroker_ecs_fargate"

  cluster_configuration = {
    execute_command_configuration = {
      logging = "OVERRIDE"
      log_configuration = {
        cloud_watch_log_group_name = var.cloudwatch_log_group_name
      }
    }
  }

  fargate_capacity_providers = {
    FARGATE = {
      default_capacity_provider_strategy = {
        weight = 50
      }
    }
    FARGATE_SPOT = {
      default_capacity_provider_strategy = {
        weight = 50
      }
    }
  }

  tags = local.tags
}

module "snykbroker_ecs_task_definition" {
  source  = "umotif-public/ecs-fargate-task-definition/aws"
  version = "2.1.2"

  enabled                = true
  name_prefix            = "snykbroker"
  # use custom image if specified, otherwise an official snyk dockerhub image based on integration type
  task_container_image   = var.image != null ? var.image : local.image
  container_name         = "snykbroker"
  task_container_port    = local.broker_port
  task_host_port         = local.broker_port
  task_definition_cpu    = var.cpu
  task_definition_memory = var.memory

  create_repository_credentials_iam_policy = true
  repository_credentials                   = module.secrets_manager.secret_arns["dockerhub_read"]
  task_container_environment               = local.broker_env_vars
  tags = local.tags
}

resource "aws_ecs_service" "snykbroker_service" {
  name            = var.service_name
  cluster         = module.snyk_ecs_cluster.cluster_id
  task_definition = module.snykbroker_ecs_task_definition.task_definition_arn
  desired_count   = var.service_desired_count
  launch_type     = var.launch_type
  scheduling_strategy  = var.scheduling_strategy
  force_new_deployment = true

  dynamic "network_configuration" {
    for_each = var.service_task_network_mode == "awsvpc" ? ["true"] : []
    content {
      subnets          = module.snykbroker_vpc.private_subnets
      security_groups  = [module.snykbroker_security_group.security_group_id]
      assign_public_ip = false
    }
  }
  tags = local.tags
}
