variable "service_azs" {
  description = "count of service availability zones to use"
  type        = number
  default     = 2
}

variable "service_name" {
  description = "Snyk broker service name"
  type        = string
  default     = "SnykBroker"
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

variable "service_task_network_mode" {
  description = "Network mode used for containers in task"
  type        = string
  default     = "awsvpc"
}

variable "attach_to_load_balancer" {
  description = "Whether to attach load balancer to broker service"
  type        = bool
  default     = false
}

variable "cloudwatch_log_group_name" {
  description = "SnykBroker CloudWatch log group name"
  type        = string
  default     = "/aws/ecs/snykbroker"
}

# Snyk broker Task specifications

# see https://github.com/snyk/broker
variable "snyk_integration_images" {
  description = "Map of Snyk integration type to default Snyk Docker image tag"
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
  description = "Map of Snyk broker environment variables key-value pairs"
  type        = map(string)
  default     = {}
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

variable "default_broker_port" {
  description = "Default snykbroker client port"
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
  default     = "snyk/broker:github-com"
}

variable "integration_type" {
  description = "Snyk Integration type.Current supported are GitHub.com, GitHub-Enterprise. "
  type        = string
  default     = ""
}

variable "tags" {
  description = "Tags"
  type        = map(string)
  default     = {}
}

# Credentials to DockerHub for pull of snyk broker image
variable "dockerhub_username" {
  description = "DockerHub username"
  type        = string
  default     = null
}

variable "dockerhub_access_token" {
  description = "DockerHub personal access token"
  type        = string
  default     = null
}
