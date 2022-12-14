output "snykbroker_aws_dns_name" {
  description = "SnykBroker Client AWS DNS name"
  value       = module.snykbroker_lb.lb_dns_name
}

output "snykbroker_lb_dns_name" {
  description = "SnykBroker Client hosted domain DNS name"
  value       = try(values(module.snykbroker_lb_route53_record.route53_record_fqdn)[0], "")
}

output "snykbroker_client_healthcheck_url" {
  description = "SnykBroker Client healthcheck URL"
  value = format("%s/healthcheck", local.broker_client_url)
}

output "snykbroker_client_systemcheck_url" {
  description = "SnykBroker Client systemcheck URL"
  value = format("%s/systemcheck", local.broker_client_url)
}
