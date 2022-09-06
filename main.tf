data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_route53_zone" "public_zone" {
  count = var.use_existing_route53_zone ? 1 : 0

  name         = local.domain_name
  private_zone = false
}

module "snykbroker_vpc" {
  source = "terraform-aws-modules/vpc/aws"
  version = "3.14.3"

  name = "snykbroker_vpc"
  cidr = var.vpc_cidr

  # select the first grouping of specified number of service_azs
  azs             = chunklist(data.aws_availability_zones.available.names, var.service_azs)[0]
  # split half cidr for private, half for public and then subdivide each by number of service availability zones
  private_subnets = [for x in range(var.service_azs) : cidrsubnet(cidrsubnet(var.vpc_cidr, 1, 0), 3, x)]
  public_subnets  = [for x in range(var.service_azs) : cidrsubnet(cidrsubnet(var.vpc_cidr, 1, 1), 3, x)]
  # One NAT Gateway per subnet (default)
  enable_nat_gateway   = true
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = local.tags
}

module "snykbroker_lb_security_group" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "4.13.0"

  name        = "snykbroker_lb"
  description = "Security group for SnykBroker load balancer"
  vpc_id      = module.snykbroker_vpc.vpc_id

  # allow ingress of https from SCM webhooks
  ingress_cidr_blocks = ["0.0.0.0/0"]
  ingress_rules       =  var.broker_protocol == "https" ? ["https-443-tcp"] : []
  ingress_with_cidr_blocks = var.broker_protocol == "http" ? [
    {
      from_port   = local.broker_port
      to_port     = local.broker_port
      protocol    = "tcp"
      description = "SnykBroker Client HTTP port"
      cidr_blocks = "0.0.0.0/0"
    }
  ] : []
  # allow egress of broker client container security group
  computed_egress_with_source_security_group_id = [
    {
      from_port   = local.broker_port
      to_port     = local.broker_port
      protocol    = "tcp"
      description = "SnykBroker client port for webhook access"
      source_security_group_id = module.snykbroker_security_group.security_group_id
    }
  ]
  number_of_computed_egress_with_source_security_group_id = 1
}

module "snykbroker_security_group" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "4.13.0"

  name        = "snykbroker_service"
  description = "Security group for SnykBroker fargate service"
  vpc_id      = module.snykbroker_vpc.vpc_id

  # allow ingress from its public facing load balancer
  computed_ingress_with_source_security_group_id = [
    {
      from_port   = local.broker_port
      to_port     = local.broker_port
      protocol    = "tcp"
      description = "SnykBroker client port for webhook access"
      source_security_group_id = module.snykbroker_lb_security_group.security_group_id
    }
  ]
  number_of_computed_ingress_with_source_security_group_id = 1
  egress_cidr_blocks      = ["0.0.0.0/0"]
  egress_rules            = ["https-443-tcp"]
  egress_with_source_security_group_id = var.use_private_ssl_cert ? [
    {
      rule                     = "nfs-tcp"
      source_security_group_id = module.snykbroker_efs[0].sg_id
    }
  ] : []

  tags = local.tags
}

module "snykbroker_log_group" {
  source  = "terraform-aws-modules/cloudwatch/aws//modules/log-group"
  version = "3.3.0"

  name              = var.cloudwatch_log_group_name
  kms_key_id        = module.snykbroker_kms.key_arn
  retention_in_days = var.cloudwatch_log_retention_days
}

module "snykbroker_ecs_cluster" {
  source  = "terraform-aws-modules/ecs/aws"
  version = "4.1.1"

  cluster_name = "snykbroker_ecs_fargate"

  cluster_configuration = {
    execute_command_configuration = {
      logging = "OVERRIDE"
      log_configuration = {
        cloud_watch_log_group_name = module.snykbroker_log_group.cloudwatch_log_group_name
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

  enabled                   = true
  name_prefix               = var.service_name
  # use custom image if specified, otherwise an official snyk dockerhub image based on integration type
  task_container_image      = var.image != null ? var.image : local.image
  container_name            = var.container_name
  task_container_port       = local.broker_port
  task_host_port            = local.broker_port
  task_definition_cpu       = var.cpu
  task_definition_memory    = var.memory
  cloudwatch_log_group_name = module.snykbroker_log_group.cloudwatch_log_group_name

  create_repository_credentials_iam_policy = true
  repository_credentials_kms_key           = module.snykbroker_kms.key_id
  repository_credentials                   = module.snykbroker_secrets.secret_arns["dockerhub_r"]
  task_container_environment               = local.broker_env_vars
  task_container_secrets                   = [for t in aws_ssm_parameter.tokens : tomap({"name" = t.description, "valueFrom" = t.arn})]

  task_stop_timeout = 90

  task_mount_points = var.use_private_ssl_cert ? [
    {
      sourceVolume  = var.service_name
      containerPath = local.mount_path
      readOnly      = true
    }
  ] : []

  # volume name corresponds to sourceVolume which will contain a cert directory with cert injected by a lambda function
  volume = var.use_private_ssl_cert ? [
    {
      name = var.service_name
      efs_volume_configuration = [
        {
          file_system_id       = module.snykbroker_efs[0].efs_id
          # root_directory       = "/cert omitted with access point use"
          transit_encryption   = "ENABLED"
          authorization_config = {
            access_point_id = aws_efs_access_point.snykbroker_cert_access_point[0].id
            iam             = "ENABLED"
          }
        }
      ]
    }
  ] : []
  tags = local.tags
}

module "snykbroker_lb" {
  source  = "terraform-aws-modules/alb/aws"
  version = "7.0.0"

  name               = var.service_name
  # launch external facing ALB that accepts http/https traffic from webhook requests of cloud-hosted SCMs
  load_balancer_type = "application"
  internal           = false
  vpc_id             = module.snykbroker_vpc.vpc_id
  subnets            = module.snykbroker_vpc.public_subnets
  security_groups    = [module.snykbroker_lb_security_group.security_group_id]

  enable_cross_zone_load_balancing = true
  # turn on alb access logging to s3 bucket if bucket name provided
  access_logs = var.log_bucket_name != null ? {
    bucket = var.log_bucket_name
  } : {}

  target_groups = [
    {
      name_prefix       = "snyk-"
      backend_protocol  = var.use_private_ssl_cert ? "HTTPS" : "HTTP"
      backend_port      = local.broker_port
      target_type       = "ip"
    }
  ]

  https_listeners = var.broker_protocol == "https" ? [
    {
      port               = 443
      protocol           = upper(var.broker_protocol)
      certificate_arn    = module.snykbroker_acm.acm_certificate_arn
      target_group_index = 0
    }
  ] : []

  http_tcp_listeners = var.broker_protocol == "http" ? [
    {
      port               = local.broker_port
      protocol           = upper(var.broker_protocol)
      target_group_index = 0
    }
  ] : []

  tags = local.tags
}

module "snykbroker_efs" {
  count   = var.use_private_ssl_cert ? 1 : 0
  source  = "terraform-iaac/efs/aws"
  version = "2.0.4"
  # insert the 5 required variables here
  name       = var.service_name
  vpc_id     = module.snykbroker_vpc.vpc_id
  subnet_ids = module.snykbroker_vpc.private_subnets
  encrypted  = true
  kms_key_id = module.snykbroker_kms.key_arn
  # allowed ingress from private subnets cidr
  whitelist_cidr = module.snykbroker_vpc.private_subnets_cidr_blocks

  tags = local.tags
}

# umotif-public/terraform-aws-ecs-fargate module v6.5.2 is not used because it does not parameterize a hardened security group
resource "aws_ecs_service" "snykbroker_service" {
  name            = var.service_name
  cluster         = module.snykbroker_ecs_cluster.cluster_id
  task_definition = module.snykbroker_ecs_task_definition.task_definition_arn
  desired_count   = var.service_desired_count
  launch_type     = var.launch_type
  scheduling_strategy  = var.scheduling_strategy
  force_new_deployment = true

  network_configuration {
    subnets          = module.snykbroker_vpc.private_subnets
    security_groups  = [module.snykbroker_security_group.security_group_id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = module.snykbroker_lb.target_group_arns[0]
    container_name   = var.container_name
    container_port   = local.broker_port
  }

  tags = local.tags
  depends_on = [aws_lambda_invocation.snykbroker_lambda_invocation]
}

# creates <public_domain_name> public hosted zone if non-existent
module "public_route53_zone" {
  count = !var.use_existing_route53_zone ? 1 : 0
  source  = "terraform-aws-modules/route53/aws//modules/zones"
  version = "2.9.0"
  zones = {
    (local.domain_name) = {
      comment = "Public ${local.domain_name} hosted zone"
      # force destroy for repeated iac testing
      force_destroy = true
    }
  }

  tags = local.tags
}

# create load balancer route53 record "<broker_hostname>.<public_domain_name>"
# this requires AWS Route53 to manage DNS on a public hosted zone defined by its public domain name
module "snykbroker_lb_route53_record" {
  source  = "terraform-aws-modules/route53/aws//modules/records"
  version = "2.9.0"
  zone_name = local.domain_name

  records = [
    {
      name    = var.broker_hostname
      type    = "A"
      alias   = {
        name                   = module.snykbroker_lb.lb_dns_name
        zone_id                = module.snykbroker_lb.lb_zone_id
        evaluate_target_health = true
      }
    }
  ]

  # in case of creating the public hosted zone
  depends_on = [module.public_route53_zone]
}

# creates a default Route53 DNS validated public certificate for the load balancer use
module "snykbroker_acm" {
  source  = "terraform-aws-modules/acm/aws"
  version = "4.0.1"

  create_certificate = var.broker_protocol == "https" ? true : false
  domain_name = format("%s.%s", var.broker_hostname, local.domain_name)
  zone_id     = coalescelist(data.aws_route53_zone.public_zone.*.zone_id, try(values(module.public_route53_zone[0].route53_zone_zone_id), []))[0]

  wait_for_validation = true

  tags = local.tags
}
