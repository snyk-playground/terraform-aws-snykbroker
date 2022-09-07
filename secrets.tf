module "snykbroker_secrets" {
  source  = "lgallard/secrets-manager/aws"
  version = "0.6.0"

  secrets = {
    dockerhub_r = {
      description = "DockerHub read scope access credentials"
      kms_key_id  = module.snykbroker_kms.key_id
      secret_key_value = {
        username = var.dockerhub_username
        password = var.dockerhub_access_token
      }
      tags = var.tags
      recovery_window_in_days = 0
    },
  }

  tags = var.tags
}

module "snykbroker_kms" {
  source  = "terraform-aws-modules/kms/aws"
  version = "1.1.0"
  aliases     = [var.service_name]
  description = "SnykBroker KMS key"
  # key used for encrypting snykbroker cloudwatch log groups
  source_policy_documents = [data.aws_iam_policy_document.snykbroker_logs_policy_doc.json]

  tags = var.tags
}

# SSM parameters for sensitive TOKEN values
resource "aws_ssm_parameter" "tokens" {
  for_each    = local.sensitive_env_vars
  name        = format("/%s/%s", var.service_name, each.key)
  type        = "SecureString"
  value       = each.value
  description = each.key
  key_id      = module.snykbroker_kms.key_id
  overwrite   = true
  tags        = var.tags
}
