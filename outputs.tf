output "broker_client_url" {
  description = "SnykBroker Client URL"
  value       = try(lookup(local.broker_env_vars, "BROKER_CLIENT_URL", ""), "")
  sensitive   = false
}
