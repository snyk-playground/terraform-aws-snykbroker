module "secrets_manager" {
  source  = "lgallard/secrets-manager/aws"
  version = "0.5.2"

  secrets = {
    dockerhub_read = {
      description = "DockerHub credential"
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
