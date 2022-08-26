output "aws_broker_dns_name" {
  description = "AWS generated SnykBroker Client DNS name"
  value       = module.snykbroker_nlb.lb_dns_name
}

output "snykbroker_lb_dns_name" {
  description = "SnykBroker Client load balancer DNS name"
  value       = try(values(module.snykbroker_lb_route53_record.route53_record_fqdn)[0], "")
}
