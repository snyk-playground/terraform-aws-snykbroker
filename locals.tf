locals {
  # derive specific dockerhub image to pull
  create_cra            = var.integration_type == "cra"
  cr_ecr                = local.create_cra && lookup(var.broker_env_vars, "CR_TYPE", "") == "ecr"
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
    for v in local.env_vars : v => lookup(var.broker_env_vars, v, "<non-sensitive-string>")
      if length(regexall("(TOKEN)$", v)) > 0 || length(regexall("(PASSWORD)$", v)) > 0
  }
  # Broker client related container registry env variables
  cra_lb_port        = var.broker_protocol == "https" ? 443 : var.cra_port
  cr_agent_url       = local.create_cra ? format("%s://%s:%s", var.broker_protocol, try(values(module.cra_lb_route53_record[0].route53_record_fqdn)[0], module.cra_lb[0].lb_dns_name), local.cra_lb_port) : null
  cr_vars = local.create_cra ? {
    CR_AGENT_URL                 = local.cr_agent_url
    BROKER_CLIENT_VALIDATION_URL = "${local.cr_agent_url}/systemcheck"
  } : {}
  cr_ecr_vars = local.cr_ecr ? {
    CR_ROLE_ARN    = module.cra_ecr_snyk_assumable_role[0].iam_role_arn
    CR_REGION      = lookup(var.broker_env_vars, "CR_REGION", data.aws_region.current.name)
  } : {}
  # computed env vars take precedence over same env keys at var.broker_env_vars if any
  broker_env_vars       = merge({
    for v in local.env_vars : v => lookup(var.broker_env_vars, v, "")
      if length(regexall("(TOKEN)$", v)) == 0 && length(regexall("(PASSWORD)$", v)) == 0
  }, local.computed_env_vars, local.cert_env_vars, local.listing_filter_env_var, var.additional_env_vars, local.cr_vars, local.cr_ecr_vars)

  # remove trailing dot from domain if any
  domain_name = trimsuffix(var.public_domain_name, ".")
  attach_config  = var.private_ssl_cert || var.custom_listing_filter || var.cra_private_ssl_cert

  # container registry agent
  cra_image              = "${var.cra_repo}:${var.cra_image_tag}"
  private_subdomain_name = "private.${local.domain_name}"
  cra_cert_env_vars      = var.cra_private_ssl_cert ? tomap({
    "HTTPS_CERT" = format("%s/%s", local.mount_path, element(split("/", var.cra_ssl_cert_object), length(split("/", var.cra_ssl_cert_object))-1))
    "HTTPS_KEY"  = format("%s/%s", local.mount_path, element(split("/", var.cra_private_key_object), length(split("/", var.cra_private_key_object))-1))
  }) : {}
  cra_required_env_vars  = {
    "SNYK_PORT" = var.cra_port
  }
  cra_env_vars           = merge(local.cra_required_env_vars, local.cra_cert_env_vars)
}
