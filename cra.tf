module "cra_lb_security_group" {
  count   = local.create_cra ? 1 : 0
  source  = "terraform-aws-modules/security-group/aws"
  version = "4.13.0"

  name        = "cra_lb"
  description = "Security group for Container Registry Agent load balancer"
  vpc_id      = module.snykbroker_vpc.vpc_id

  # allow ingress from Broker Client
  computed_ingress_with_source_security_group_id = [
    {
      from_port   = var.broker_protocol == "https" ? 443 : var.cra_port
      to_port     = var.broker_protocol == "https" ? 443 : var.cra_port
      protocol    = "tcp"
      description = "Ingress from broker client"
      source_security_group_id = module.snykbroker_security_group.security_group_id
    }
  ]
  number_of_computed_ingress_with_source_security_group_id = 1
  # allow egress of broker client container security group
  computed_egress_with_source_security_group_id = [
    {
      from_port   = var.cra_port
      to_port     = var.cra_port
      protocol    = "tcp"
      description = "Container registry agent port"
      source_security_group_id = module.cra_security_group[0].security_group_id
    }
  ]
  number_of_computed_egress_with_source_security_group_id = 1
}

module "cra_security_group" {
  count   = local.create_cra ? 1 : 0
  source  = "terraform-aws-modules/security-group/aws"
  version = "4.13.0"

  name        = "cra_service"
  description = "Security group for Container Registry Agent fargate service"
  vpc_id      = module.snykbroker_vpc.vpc_id

  # allow ingress from its load balancer
  computed_ingress_with_source_security_group_id = [
    {
      from_port   = var.cra_port
      to_port     = var.cra_port
      protocol    = "tcp"
      description = "Container registry agent port"
      source_security_group_id = module.cra_lb_security_group[0].security_group_id
    }
  ]
  number_of_computed_ingress_with_source_security_group_id = 1
  egress_cidr_blocks      = ["0.0.0.0/0"]
  egress_rules            = ["https-443-tcp"]
  egress_with_source_security_group_id = local.attach_config ? [
    {
      rule                     = "nfs-tcp"
      source_security_group_id = module.snykbroker_efs[0].sg_id
    }
  ] : []

  tags = var.tags
}

module "cra_lb" {
  count   = local.create_cra ? 1 : 0
  source  = "terraform-aws-modules/alb/aws"
  version = "7.0.0"

  name               = var.cra_name
  # launch internal ALB that accepts http/https traffic from SnykBroker client
  load_balancer_type = "application"
  internal           = true
  vpc_id             = module.snykbroker_vpc.vpc_id
  subnets            = module.snykbroker_vpc.private_subnets
  security_groups    = [module.cra_lb_security_group[0].security_group_id]

  enable_cross_zone_load_balancing = true
  # turn on alb access logging to s3 bucket if bucket name provided
  access_logs = var.log_bucket_name != null ? {
    bucket = var.log_bucket_name
  } : {}

  target_groups = [
    {
      name_prefix       = "snyk-"
      backend_protocol  = var.cra_private_ssl_cert ? "HTTPS" : "HTTP"
      backend_port      = var.cra_port
      target_type       = "ip"
      health_check = {
        enabled             = true
        interval            = 30
        path                = "/healthcheck"
        port                = "traffic-port"
        healthy_threshold   = 3
        unhealthy_threshold = 3
        timeout             = 10
        protocol            = var.cra_private_ssl_cert ? "HTTPS" : "HTTP"
        matcher             = "200-299"
      }
    }
  ]

  https_listeners = var.broker_protocol == "https" ? [
    {
      port               = 443
      protocol           = upper(var.broker_protocol)
      certificate_arn    = module.cra_acm[0].acm_certificate_arn
      target_group_index = 0
    }
  ] : []

  http_tcp_listeners = var.broker_protocol == "http" ? [
    {
      port               = var.cra_port
      protocol           = upper(var.broker_protocol)
      target_group_index = 0
    }
  ] : []

  tags = var.tags
}

# creates private hosted zone
module "private_route53_zone" {
  count   = local.create_cra ? 1 : 0
  source  = "terraform-aws-modules/route53/aws//modules/zones"
  version = "2.9.0"
  zones = {
    (local.private_subdomain_name) = {
      comment = "Private ${local.domain_name} hosted zone"
      vpc = [
        {
          vpc_id = module.snykbroker_vpc.vpc_id
        },
      ]
      # force destroy for repeated iac testing
      force_destroy = true
    }
  }

  tags = var.tags
}

# create load balancer route53 record "<cra_hostname>.private.<public_domain_name>" in private zone
module "cra_lb_route53_record" {
  count   = local.create_cra ? 1 : 0
  source  = "terraform-aws-modules/route53/aws//modules/records"
  version = "2.9.0"
  zone_name = lookup(module.private_route53_zone[0].route53_zone_name, local.private_subdomain_name, "")
  private_zone = true

  records = [
    {
      name    = var.cra_hostname
      type    = "A"
      alias   = {
        name                   = module.cra_lb[0].lb_dns_name
        zone_id                = module.cra_lb[0].lb_zone_id
        evaluate_target_health = true
      }
    }
  ]
  depends_on = [module.private_route53_zone]
}

# creates a default Route53 DNS validated public certificate for the load balancer use
module "cra_acm" {
  count   = local.create_cra ? 1 : 0
  source  = "terraform-aws-modules/acm/aws"
  version = "4.0.1"

  create_certificate = var.broker_protocol == "https" ? true : false
  domain_name = format("%s.%s", var.cra_hostname, local.private_subdomain_name)
  # public cert can only be validated on public hosted zone
  zone_id     = coalescelist(data.aws_route53_zone.public_zone.*.zone_id, try(values(module.public_route53_zone[0].route53_zone_zone_id), []))[0]

  wait_for_validation = true

  tags = var.tags
}

module "cra_ecs_task_definition" {
  count   = local.create_cra ? 1 : 0
  source  = "umotif-public/ecs-fargate-task-definition/aws"
  version = "2.1.2"

  enabled                   = true
  name_prefix               = var.cra_name
  # use custom image if specified, otherwise an official snyk dockerhub image based on integration type
  task_container_image      = local.cra_image
  container_name            = var.cra_container_name
  task_container_port       = var.cra_port
  task_host_port            = var.cra_port
  task_definition_cpu       = var.cpu
  task_definition_memory    = var.memory
  cloudwatch_log_group_name = module.snykbroker_log_group.cloudwatch_log_group_name

  task_container_environment = local.cra_env_vars
  task_stop_timeout = 90
  task_mount_points = local.attach_config ? [
    {
      sourceVolume  = var.cra_name
      containerPath = local.mount_path
      readOnly      = true
    }
  ] : []

  # volume name corresponds to sourceVolume which will contain a cert directory with cert injected by a lambda function
  volume = local.attach_config ? [
    {
      name = var.cra_name
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
  tags = var.tags
}

resource "aws_ecs_service" "cra_service" {
  count           = local.create_cra ? 1 : 0
  name            = var.cra_name
  cluster         = module.snykbroker_ecs_cluster.cluster_id
  task_definition = module.cra_ecs_task_definition[0].task_definition_arn
  desired_count   = var.cra_desired_count
  launch_type     = var.launch_type
  scheduling_strategy  = var.scheduling_strategy
  force_new_deployment = true

  network_configuration {
    subnets          = module.snykbroker_vpc.private_subnets
    security_groups  = [module.cra_security_group[0].security_group_id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = module.cra_lb[0].target_group_arns[0]
    container_name   = var.cra_container_name
    container_port   = var.cra_port
  }

  tags = var.tags
  depends_on = [aws_lambda_invocation.snykbroker_lambda_invocation]
}
