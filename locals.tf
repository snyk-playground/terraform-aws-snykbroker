locals {
  # derive specific dockerhub image to pull
  image_tag             = lookup(var.snyk_integration_images, var.integration_type, "")
  image                 = format("%s:%s", var.snykbroker_repo, local.image_tag)
  # environment variables key-value pairs
  env_vars              = lookup(var.snyk_integration_env_vars, var.integration_type, [])
  broker_port           = var.broker_port
  broker_lb_port        = var.broker_protocol == "https" ? 443 : local.broker_port
  broker_client_url     = format("%s://%s:%s", var.broker_protocol, try(values(module.snykbroker_lb_route53_record.route53_record_fqdn)[0], module.snykbroker_lb.lb_dns_name), local.broker_lb_port)
  # certificate env vars
  mount_path            = "/mnt/shared"
  cert_env_vars         = var.private_ssl_cert ? tomap({
    "HTTPS_CERT" = format("%s/%s", local.mount_path, element(split("/", var.broker_ssl_cert_object), length(split("/", var.broker_ssl_cert_object))-1))
    "HTTPS_KEY"  = format("%s/%s", local.mount_path, element(split("/", var.broker_private_key_object), length(split("/", var.broker_private_key_object))-1))
  }) : {}
  listing_filter_env_var = var.custom_listing_filter ? tomap({
    "ACCEPT" = format("%s/%s", local.mount_path, element(split("/", var.broker_accept_json_object), length(split("/", var.broker_accept_json_object))-1))
  }) : {}
  computed_env_vars     = {
    "BROKER_CLIENT_URL" = local.broker_client_url
    "PORT"              = local.broker_port
  }
  sensitive_env_vars = {
    for v in local.env_vars : v => lookup(var.broker_env_vars, v, "")
      if length(regexall("(TOKEN)$", v)) > 0
  }
  # computed env vars take precedence over same env keys at var.broker_env_vars if any
  broker_env_vars       = merge({
    for v in local.env_vars : v => lookup(var.broker_env_vars, v, "")
      if length(regexall("(TOKEN)$", v)) == 0
  }, local.computed_env_vars, local.cert_env_vars, local.listing_filter_env_var, var.additional_env_vars)

  # remove trailing dot from domain if any
  domain_name = trimsuffix(var.public_domain_name, ".")
  attach_config  = var.private_ssl_cert || var.custom_listing_filter
}
