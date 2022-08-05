output "aws_broker_dns_name" {
  description = "AWS generated SnykBroker Client DNS name"
  value       = module.snykbroker_nlb.lb_dns_name
}

output "broker_client_url" {
  description = "SnykBroker Client URL"
  value       = try(lookup(local.broker_env_vars, "BROKER_CLIENT_URL", ""), "")
  sensitive   = true
}
