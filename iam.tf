data "aws_iam_policy_document" "snykbroker_kms_policy_doc" {
  statement {
    actions = [
      "kms:Decrypt",
      "kms:Encrypt",
      "kms:GenerateDataKey",
      "kms:ReEncrypt*",
    ]
    resources = [
      module.snykbroker_kms.key_arn,
    ]
  }
}

module "snykbroker_kms_iam_policy" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-policy"
  version = "3.5.0"

  description = "SnykBroker KMS key usage policy"
  name        = "snykbroker_kms_policy"
  path        = "/"
  policy      = data.aws_iam_policy_document.snykbroker_kms_policy_doc.json
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
