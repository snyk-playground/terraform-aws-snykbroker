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
  version = "3.5.0"

  description = "SnykBroker KMS key usage policy"
  name        = "snykbroker_kms_policy"
  path        = "/"
  policy      = data.aws_iam_policy_document.snykbroker_secrets_policy_doc.json
  tags        = var.tags
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
