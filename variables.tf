# SnykBroker vpc
variable "vpc_cidr" {
  description = "SnykBroker VPC cidr. Linked to service_azs to be created"
  type        = string
  default     = "192.168.0.0/20"
}

variable "service_azs" {
  description = "count of service availability zones to use"
  type        = number
  default     = 2
}

variable "service_name" {
  description = "Snyk broker service name"
  type        = string
  default     = "snykbroker"
}

variable "service_desired_count" {
  description = "Snyk broker service instance count"
  type        = number
  default     = 1
}

variable "launch_type" {
  description = "SnykBroker service launch type"
  type        = string
  default     = "FARGATE"
}

variable "scheduling_strategy" {
  description = "Snyk broker scheduling strategy"
  type        = string
  default     = "REPLICA"
}

variable "container_name" {
  description = "Snyk broker container name behind the Service"
  type        = string
  default     = "snykbroker"
}

variable "fargate_capacity_base" {
  description = "Fargate capacity provider base as minimum number of Tasks. Only this or fargate_spot_capacity_base can be >0"
  type        = number
  default     = 0
}

variable "fargate_capacity_weight" {
  description = "Fargate capacity provider weight as a relative percentage of total service_desired_count Tasks"
  type        = number
  default     = 50
}

variable "fargate_spot_capacity_base" {
  description = "Fargate Spot capacity provider base as minimum number of Tasks. Only this or fargate_capacity_base can be >0"
  type        = number
  default     = 0
}

variable "fargate_spot_capacity_weight" {
  description = "Fargate Spot capacity provider weight as a relative percentage of total service_desired_count Tasks"
  type        = number
  default     = 50
}

variable "cloudwatch_log_group_name" {
  description = "SnykBroker CloudWatch log group name"
  type        = string
  default     = "/aws/ecs/snykbroker"
}

variable "cloudwatch_log_retention_days" {
  description = "SnykBroker CloudWatch log retention in days"
  type        = number
  default     = 7
}

# Snyk broker Task specifications

# see https://github.com/snyk/broker
variable "snyk_integration_images" {
  description = "Map of Snyk integration type to default official Snyk Docker image tag"
  type        = map(string)
  default     = {
    "gh"          = "github-com"
    "ghe"         = "github-enterprise"
    "bitbucket"   = "bitbucket-server"
    "gitlab"      = "gitlab"
    "azurerepos"  = "azure-repos"
    "artifactory" = "artifactory"
    "nexus"       = "nexus"
    "jira"        = "jira"
  }
}

# see https://github.com/snyk/broker
variable "snyk_integration_env_vars" {
  description = "Map of Snyk integration type to environment values at the broker container"
  type        = map(list(string))
  default     = {
    "gh"          = ["BROKER_TOKEN", "GITHUB_TOKEN", "PORT", "BROKER_CLIENT_URL"]
    "ghe"         = ["BROKER_TOKEN", "GITHUB_TOKEN", "GITHUB", "GITHUB_API", "GITHUB_GRAPHQL", "PORT", "BROKER_CLIENT_URL"]
    "bitbucket"   = ["BROKER_TOKEN", "BITBUCKET_USERNAME", "BITBUCKET_PASSWORD", "BITBUCKET", "BITBUCKET_API", "BROKER_CLIENT_URL", "PORT"]
    "gitlab"      = ["BROKER_TOKEN", "GITLAB_TOKEN", "GITLAB", "PORT", "BROKER_CLIENT_URL"]
    "azurerepos"  = ["BROKER_TOKEN", "AZURE_REPOS_TOKEN", "AZURE_REPOS_ORG", "AZURE_REPOS_HOST", "PORT", "BROKER_CLIENT_URL"]
    "artifactory" = ["BROKER_TOKEN", "ARTIFACTORY_URL"]
    "nexus"       = ["BROKER_TOKEN", "BASE_NEXUS_URL", "BROKER_CLIENT_VALIDATION_URL", "RES_BODY_URL_SUB"]
    "jira"        = ["BROKER_TOKEN", "JIRA_USERNAME", "JIRA_PASSWORD", "JIRA_HOSTNAME", "BROKER_CLIENT_URL", "PORT"]
  }
}

# see https://github.com/snyk/broker
# user specified environment key-value pairs should include all required ones at snyk_integration_env_vars
variable "broker_env_vars" {
  description = "SnykBroker environment variables key-value pairs. PORT, BROKER_CLIENT_URL not required"
  type        = map(string)
  default     = {}
  sensitive   = true
}

# additional environment values
variable "additional_env_vars" {
  description = "Additional environment variables"
  type        = map(string)
  default     = {}
}

variable "snykbroker_repo" {
  description = "DockerHub snyk broker repo"
  type        = string
  default     = "snyk/broker"
}

variable "broker_protocol" {
  description = "Protocol for running connections to SnykBroker. Either http or https"
  type        = string
  default     = "https"
}

variable "broker_port" {
  description = "Default snykbroker client port. Set a non-system port i.e. >= 1024 as container run-as non-root user"
  type        = number
  default     = 7341
}

variable "cpu" {
  description = "Broker service task CPU. min 256 i.e. 0.25 vCPU, max 4096 i.e. 4 vCPU"
  type        = number
  default     = 256
}

variable "memory" {
  description = "Broker service memory in MiB. Min 512, max 30720"
  type        = number
  default     = 512
}

variable "image" {
  description = "Broker image to pull from DockerHub. May be custom derived broker image"
  type        = string
  default     = null
}

variable "integration_type" {
  description = "Snyk Integration type. Choice of artifactory, azurerepos, bitbucket, gh, ghe, gitlab, jira or nexus"
  type        = string
  default     = ""
}

variable "log_bucket_name" {
  description = "snykbbroker requests access log bucket name for logging webhooks requests"
  type        = string
  default     = null
}

variable "tags" {
  description = "Tags"
  type        = map(string)
  default     = {}
}

variable "default_tags" {
  description = "Default Tags at aws provider scope"
  type        = map(string)
  default     = {
    "Snyk" = "SnykBroker"
  }
}

# Credentials to DockerHub for pull of snyk broker image
variable "dockerhub_username" {
  description = "DockerHub username"
  type        = string
  default     = null
  sensitive   = true
}

variable "dockerhub_access_token" {
  description = "DockerHub personal access token"
  type        = string
  default     = null
  sensitive   = true
}

variable "public_domain_name" {
  description = "Customer public domain e.g. example.com"
  type        = string
  default     = null
}

variable "broker_hostname" {
  description = "SnykBroker hostname. <broker_hostname>.<public_domain_name> forms its FQDN for SCM webhooks calls"
  type        = string
  default     = "snykbroker"
}

variable "use_existing_route53_zone" {
  description = "Use existing public hosted zone of <public_domain_name> or create new zone"
  type        = bool
  default     = true
}

# handling of SnykBroker private key and cert usage
variable "private_ssl_cert" {
  description = "Use private SSL certificate at SnykBroker client"
  type        = bool
  default     = false
}

variable "custom_listing_filter" {
  description = "Use custom approved listing filter i.e. a revised accept.json"
  type        = bool
  default     = false
}

variable "config_bucket_name" {
  description = "Configuration S3 bucket name storing SnykBroker private key, SSL certificate, accept.json filter, etc"
  type        = string
  default     = null
}

variable "broker_private_key_object" {
  description = "S3 object of SnykBroker certificate private key. Example <s3folder>/<name>.key"
  type        = string
  default     = null
}

variable "broker_ssl_cert_object" {
  description = "S3 object of SnykBroker certificate. Example <s3folder>/<name>.pem"
  type        = string
  default     = null
}

variable "broker_accept_json_object" {
  description = "S3 object of SnykBroker listing filter accept.json. Example <s3folder>/accept.json"
  type        = string
  default     = null
}

# Lambda related variable
variable "lambda_runtime" {
  description = "Lambda function runtime. Defined by AWS supported versions."
  type        = string
  default     = "python3.9"
}
