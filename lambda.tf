# lambda function injects private key, certificate into efs volume subsequently mounted by snykbroker client container
# this will set https to be served by the container even though its cert will not be validated at the target
# https://docs.aws.amazon.com/elasticloadbalancing/latest/application/load-balancer-target-groups.html#target-group-routing-configuration
module "snykbroker_cert_handler_lambda" {
  count   = var.use_private_ssl_cert ? 1 : 0
  source  = "terraform-aws-modules/lambda/aws"
  version = "4.0.1"

  create        = var.use_private_ssl_cert
  function_name = "snykbroker_cert_copy"
  description   = "SnykBroker private certificate handler function"
  handler       = "s3obj_efs_copy.lambda_handler"
  runtime       = var.lambda_runtime

  source_path = "${path.module}/lambda/s3obj_efs_copy"

  vpc_subnet_ids         = module.snykbroker_vpc.private_subnets
  vpc_security_group_ids = [module.snykbroker_lambda_security_group[0].security_group_id]
  attach_network_policy  = true
  timeout                = 300

  attach_cloudwatch_logs_policy = true
  # IAM policies
  attach_policies    = true
  number_of_policies = 3
  policies = [
    "arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess",
    "arn:aws:iam::aws:policy/AmazonElasticFileSystemClientReadWriteAccess",
    module.snykbroker_kms_iam_policy.arn,
  ]
  role_tags = local.tags

  file_system_arn              = aws_efs_access_point.snykbroker_cert_access_point[0].arn
  file_system_local_mount_path = local.mount_path

  tags = local.tags
  # Explicitly declare dependency on EFS mount target.
  # When creating or updating Lambda functions, mount target must be in 'available' lifecycle state.
  depends_on = [module.snykbroker_efs]
}

module "snykbroker_lambda_security_group" {
  count   = var.use_private_ssl_cert ? 1 : 0
  source  = "terraform-aws-modules/security-group/aws"
  version = "4.13.0"

  create      = var.use_private_ssl_cert
  name        = "snykbroker_lambda_security"
  description = "Security group for cert handler lambda"
  vpc_id      = module.snykbroker_vpc.vpc_id

  # allows egress of https-443 to access S3 bucket, efs and lambda control plane
  egress_cidr_blocks      = ["0.0.0.0/0"]
  egress_rules            = ["https-443-tcp"]
  egress_with_source_security_group_id = [
    {
      rule                     = "nfs-tcp"
      source_security_group_id = module.snykbroker_efs[0].sg_id
    }
  ]

  tags = local.tags
}

resource "aws_efs_access_point" "snykbroker_cert_access_point" {
  count          = var.use_private_ssl_cert ? 1 : 0
  file_system_id = module.snykbroker_efs[0].efs_id

  posix_user {
    gid = 1000
    uid = 1000
  }

  # this auto-creates cert directory on efs volume mounted at this path
  root_directory {
    path = "/cert"
    creation_info {
      owner_gid   = 1000
      owner_uid   = 1000
      permissions = "0777"
    }
  }
}

# local provisioner waits 90 seconds for efs DNS records to propagate in aws region
# see https://docs.aws.amazon.com/efs/latest/ug/mounting-fs-mount-cmd-dns-name.html
resource "null_resource" "wait_lambda_efs" {
  count = var.use_private_ssl_cert ? 1 : 0
  provisioner "local-exec" {
    command = "sleep 90"
  }
  depends_on = [module.snykbroker_cert_handler_lambda]
}

# invoke injection lambda function with event map pointing to the key and cert
resource "aws_lambda_invocation" "snykbroker_lambda_invocation" {
  count = var.use_private_ssl_cert ? 1 : 0
  function_name = module.snykbroker_cert_handler_lambda[0].lambda_function_name
  input         = jsonencode({
    "bucket_name" = var.cert_bucket_name
    "s3_objects"  = [var.broker_private_key_object, var.broker_ssl_cert_object]
  })
  depends_on = [null_resource.wait_lambda_efs]
}
