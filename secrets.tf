module "snykbroker_secrets" {
  source  = "lgallard/secrets-manager/aws"
  version = "0.5.2"

  secrets = {
    dockerhub_r = {
      description = "DockerHub read scope access credentials"
      kms_key_id  = module.snykbroker_kms.key_id
      secret_key_value = {
        username = var.dockerhub_username
        password = var.dockerhub_access_token
      }
      tags = {
        app = "dockerhub"
        environment = "SnykBroker"
      }
      recovery_window_in_days = 0
    },
  }

  tags = local.tags
}

module "snykbroker_kms" {
  source  = "terraform-aws-modules/kms/aws"
  version = "1.1.0"
  aliases     = [var.service_name]
  description = "SnykBroker KMS key"

  tags = local.tags
}
