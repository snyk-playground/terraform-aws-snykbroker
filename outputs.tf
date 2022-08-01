output "snyk_required_env_vars" {
  description = "SnykBroker required environment variables"
  value       = try(lookup(var.snyk_integration_env_vars, var.integration_type, []), "")
}

output "broker_client_url" {
  description = "SnykBroker Client URL"
  value       = try(lookup(var.broker_env_vars, "BROKER_CLIENT_URL", ""), "")
}

output "undefined_env_vars" {
  description = "undefined required environment variables"
  value = {
    for k, v in local.broker_env_vars : k => v
    if v == ""
  }
}
