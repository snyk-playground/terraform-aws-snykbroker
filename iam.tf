data "aws_partition" "current" {}

data "aws_region" "current" {}

data "aws_caller_identity" "current" {}

data "aws_iam_policy_document" "snykbroker_secrets_policy_doc" {
  statement {
    actions = [
      "kms:Decrypt",
      "kms:Encrypt",
      "kms:GenerateDataKey",
      "kms:ReEncrypt*",
      "ssm:GetParameters",
    ]
    resources = flatten([
      module.snykbroker_kms.key_arn,
      [for t in aws_ssm_parameter.tokens : t.arn]
    ])
  }
}

data "aws_iam_policy_document" "snykbroker_logs_policy_doc" {
  statement {
    sid = "logs.${data.aws_region.current.name}"
    actions = [
      "kms:Decrypt",
      "kms:Encrypt",
      "kms:GenerateDataKey",
      "kms:ReEncrypt*",
      "kms:DescribeKey"
    ]
    principals {
      identifiers = ["logs.${data.aws_region.current.name}.amazonaws.com"]
      type        = "Service"
    }
    resources = ["*"]
    condition {
      test     = "ArnEquals"
      values   = ["arn:${data.aws_partition.current.partition}:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:*"]
      variable = "kms:EncryptionContext:aws:logs:arn"
    }
  }
}

module "snykbroker_kms_iam_policy" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-policy"
  version = "5.27.0"

  description = "SnykBroker KMS key usage policy"
  name        = "snykbroker_kms_policy"
  path        = "/"
  policy      = data.aws_iam_policy_document.snykbroker_secrets_policy_doc.json
}

# attach KMS policy permissions to Fargate execution role
resource "aws_iam_role_policy_attachment" "snykbroker_fargate_exe_kms" {
  policy_arn = module.snykbroker_kms_iam_policy.arn
  role       = module.snykbroker_ecs_task_definition.execution_role_name
}

# attach EFS client readonly policy permissions to Fargate execution role
resource "aws_iam_role_policy_attachment" "snykbroker_fargate_exe_efs" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonElasticFileSystemClientReadOnlyAccess"
  role       = module.snykbroker_ecs_task_definition.execution_role_name
}

# attach EFS client readonly policy permissions for efs access point usage
resource "aws_iam_role_policy_attachment" "snykbroker_fargate_task_efs" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonElasticFileSystemClientReadOnlyAccess"
  role       = module.snykbroker_ecs_task_definition.task_role_name
}

# Container registry agent
data "aws_iam_policy_document" "cra_ecr_policy_doc" {
  count = local.cr_ecr ? 1 : 0
  statement {
    actions = [
      "ecr:GetLifecyclePolicyPreview",
      "ecr:GetDownloadUrlForLayer",
      "ecr:BatchGetImage",
      "ecr:DescribeImages",
      "ecr:GetAuthorizationToken",
      "ecr:DescribeRepositories",
      "ecr:ListTagsForResource",
      "ecr:ListImages",
      "ecr:BatchCheckLayerAvailability",
      "ecr:GetRepositoryPolicy",
      "ecr:GetLifecyclePolicy",
    ]
    resources = ["*"]
  }
}

# attach EFS client readonly policy permissions to Fargate execution role
resource "aws_iam_role_policy_attachment" "cra_fargate_exe_efs" {
  count      = local.cr_ecr ? 1 : 0
  policy_arn = "arn:aws:iam::aws:policy/AmazonElasticFileSystemClientReadOnlyAccess"
  role       = module.cra_ecs_task_definition[0].execution_role_name
}

# attach EFS client readonly policy permissions for efs access point usage
resource "aws_iam_role_policy_attachment" "cra_fargate_task_efs" {
  count      = local.cr_ecr ? 1 : 0
  policy_arn = "arn:aws:iam::aws:policy/AmazonElasticFileSystemClientReadOnlyAccess"
  role       = module.cra_ecs_task_definition[0].task_role_name
}

# attach ECR access policy permissions to Container registry agent app
resource "aws_iam_role_policy_attachment" "cra_fargate_task_ecr" {
  count      = local.cr_ecr ? 1 : 0
  policy_arn = module.cra_ecr_iam_policy[0].arn
  role       = module.cra_ecs_task_definition[0].task_role_name
}

module "cra_ecr_iam_policy" {
  count   = local.cr_ecr ? 1 : 0
  source  = "terraform-aws-modules/iam/aws//modules/iam-policy"
  version = "5.27.0"

  description = "Container registry read only ecr policy for snyk"
  name        = "snyk_cra_ecr_iam_policy"
  path        = "/"
  policy      = data.aws_iam_policy_document.cra_ecr_policy_doc[0].json
}

# this assumable role is for container registry agent to assume with CR_ROLE_ARN env var
module "cra_ecr_snyk_assumable_role" {
  count   = local.cr_ecr ? 1 : 0
  source  = "terraform-aws-modules/iam/aws//modules/iam-assumable-role"
  version = "5.27.0"

  trusted_role_arns = [
    module.cra_ecs_task_definition[0].task_role_arn,
  ]
  trusted_role_services = [
    "ecs-tasks.amazonaws.com"
  ]

  create_role = true
  allow_self_assume_role = true
  role_name         = "snyk_cra_assumable_role"
  role_requires_mfa = false

  custom_role_policy_arns = [
    module.cra_ecr_iam_policy[0].arn,
  ]
  number_of_custom_role_policy_arns = 1
  tags = var.tags
}
