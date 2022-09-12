![Snyk logo](https://snyk.io/style/asset/logo/snyk-print.svg)

# terraform-aws-snykbroker

![snyk-oss-category](https://github.com/snyk-labs/oss-images/blob/main/oss-community.jpg)

Terraform reference implementation example to create and run [Snyk Broker](https://github.com/snyk/broker) as an AWS Elastic Container Service (ECS) Fargate Service.

:heavy_exclamation_mark: **Note**

`Requires a public hosted domain name managed by AWS Route53 Domain Name System (DNS) zone`

## Usage

### Prerequisites
1. Create a S3 bucket to store deployment terraform state
2. Create GitHub repository **_dev_** environment
3. Modify `env/dev/config.s3.backend`
4. Modify `env/dev/terraform.tfvars`

### GitHub Action

This GitHub CI workflow (ci.yml) accepts input for running [Snyk broker](https://github.com/snyk/broker) and deploys necessary AWS resources running SnykBroker as a Fargate Service.

### Variables

#### GitHub Repository secrets
1. [ ] AWS_ACCESS_KEY_ID
2. [ ] AWS_SECRET_ACCESS_KEY
3. [ ] DOCKERHUB_ACCESS_TOKEN
4. [ ] DOCKERHUB_USERNAME
5. [ ] SNYK_TOKEN

#### GitHub Environment secrets
1. [ ] AWS_REGION
2. [ ] BROKER_ENV_VARS

#### Broker Environment Variables (BROKER_ENV_VARS) format

This Environment variable value is specified as a map(string). Example:
```
{"BROKER_TOKEN":"xxx","GITHUB_TOKEN":"yyy"}
```

### Command Line Interface method

### Deployment Modes

| Mode       | Description                                       | Variable Settings                              |
|------------|---------------------------------------------------|------------------------------------------------|
| HTTP       | No SSL certificate                                | broker_protocol="http", private_ssl_cert=false |
| HTTPS/HTTP | Public SSL certificate, internal HTTP             | broker_protocol="https", private_ssl_cert=false |
| HTTPS      | Public SSL certificate, internal private SSL cert | broker_protocol="https", private_ssl_cert=true |

#### Public SSL certificate

Public SSL certificate for `<broker_hostname>.<public_domain_name>` is created and managed by AWS Certificate Manager (ACM) with its renewal automatically handled.

#### Private SSL certificate/Key

* Upload private SSL certificate (.pem) and its private key (.key) to a S3 bucket
* Verify S3 bucket and these objects are accessible to Terraform assumed credentials
* Set variable `config_bucket_name="<S3_bucket_name>"` 
* Set variable `broker_private_key_object="<S3_folder>/<key_name.key>"`
* Set variable `broker_ssl_cert_object="<S3_folder>/<cert_name.pem>"`

Private SSL certificate validity and renewal are handled independently by Customer.

#### Custom approved listing filter

* Upload custom [integration type](https://github.com/snyk/broker/tree/master/client-templates) accept.json to S3 bucket
* Verify S3 bucket and accept.json are accessible to Terraform assumed credentials
* Set variable `config_bucket_name="<S3_bucket_name>"`
* Set variable `custom_listing_filter="<S3_folder>/accept.json"`

### Deployment steps

1. Configure S3 backend for terraform state
2. Setup Terraform input tfvars
3. Invoke the commands defined below to create the Fargate Service that launches corresponding SnykBroker dockerized container.
```
$ terraform init -backend-config="env/dev/config.s3.tfbackend"
$ terraform plan -input=false -var-file="env/dev/terraform.tfvars" -out=tfplan
$ terraform apply "tfplan"
```

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 4.9 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | 4.25.0 |
| <a name="provider_null"></a> [null](#provider\_null) | 3.1.1 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_public_route53_zone"></a> [public\_route53\_zone](#module\_public\_route53\_zone) | terraform-aws-modules/route53/aws//modules/zones | 2.9.0 |
| <a name="module_snykbroker_acm"></a> [snykbroker\_acm](#module\_snykbroker\_acm) | terraform-aws-modules/acm/aws | 4.0.1 |
| <a name="module_snykbroker_cert_handler_lambda"></a> [snykbroker\_cert\_handler\_lambda](#module\_snykbroker\_cert\_handler\_lambda) | terraform-aws-modules/lambda/aws | 4.0.1 |
| <a name="module_snykbroker_ecs_cluster"></a> [snykbroker\_ecs\_cluster](#module\_snykbroker\_ecs\_cluster) | terraform-aws-modules/ecs/aws | 4.1.1 |
| <a name="module_snykbroker_ecs_task_definition"></a> [snykbroker\_ecs\_task\_definition](#module\_snykbroker\_ecs\_task\_definition) | umotif-public/ecs-fargate-task-definition/aws | 2.1.2 |
| <a name="module_snykbroker_efs"></a> [snykbroker\_efs](#module\_snykbroker\_efs) | terraform-iaac/efs/aws | 2.0.4 |
| <a name="module_snykbroker_kms"></a> [snykbroker\_kms](#module\_snykbroker\_kms) | terraform-aws-modules/kms/aws | 1.1.0 |
| <a name="module_snykbroker_kms_iam_policy"></a> [snykbroker\_kms\_iam\_policy](#module\_snykbroker\_kms\_iam\_policy) | terraform-aws-modules/iam/aws//modules/iam-policy | 3.5.0 |
| <a name="module_snykbroker_lambda_security_group"></a> [snykbroker\_lambda\_security\_group](#module\_snykbroker\_lambda\_security\_group) | terraform-aws-modules/security-group/aws | 4.13.0 |
| <a name="module_snykbroker_lb"></a> [snykbroker\_lb](#module\_snykbroker\_lb) | terraform-aws-modules/alb/aws | 7.0.0 |
| <a name="module_snykbroker_lb_route53_record"></a> [snykbroker\_lb\_route53\_record](#module\_snykbroker\_lb\_route53\_record) | terraform-aws-modules/route53/aws//modules/records | 2.9.0 |
| <a name="module_snykbroker_lb_security_group"></a> [snykbroker\_lb\_security\_group](#module\_snykbroker\_lb\_security\_group) | terraform-aws-modules/security-group/aws | 4.13.0 |
| <a name="module_snykbroker_log_group"></a> [snykbroker\_log\_group](#module\_snykbroker\_log\_group) | terraform-aws-modules/cloudwatch/aws//modules/log-group | 3.3.0 |
| <a name="module_snykbroker_secrets"></a> [snykbroker\_secrets](#module\_snykbroker\_secrets) | lgallard/secrets-manager/aws | 0.6.0 |
| <a name="module_snykbroker_security_group"></a> [snykbroker\_security\_group](#module\_snykbroker\_security\_group) | terraform-aws-modules/security-group/aws | 4.13.0 |
| <a name="module_snykbroker_vpc"></a> [snykbroker\_vpc](#module\_snykbroker\_vpc) | terraform-aws-modules/vpc/aws | 3.14.3 |

## Resources

| Name | Type |
|------|------|
| [aws_ecs_service.snykbroker_service](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecs_service) | resource |
| [aws_efs_access_point.snykbroker_cert_access_point](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/efs_access_point) | resource |
| [aws_iam_role_policy_attachment.snykbroker_fargate_exe_efs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.snykbroker_fargate_exe_kms](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.snykbroker_fargate_task_efs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_lambda_invocation.snykbroker_lambda_invocation](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lambda_invocation) | resource |
| [aws_ssm_parameter.tokens](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ssm_parameter) | resource |
| [null_resource.wait_lambda_efs](https://registry.terraform.io/providers/hashicorp/null/latest/docs/resources/resource) | resource |
| [aws_availability_zones.available](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/availability_zones) | data source |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |
| [aws_iam_policy_document.snykbroker_logs_policy_doc](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.snykbroker_secrets_policy_doc](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_partition.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/partition) | data source |
| [aws_region.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/region) | data source |
| [aws_route53_zone.public_zone](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/route53_zone) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_additional_env_vars"></a> [additional\_env\_vars](#input\_additional\_env\_vars) | Additional environment variables | `map(string)` | `{}` |    no    |
| <a name="input_broker_accept_json_object"></a> [broker\_accept\_json\_object](#input\_broker\_accept\_json\_object) | S3 object of SnykBroker listing filter accept.json. Example <s3folder>/accept.json | `string` | `null` |    no    |
| <a name="input_broker_env_vars"></a> [broker\_env\_vars](#input\_broker\_env\_vars) | SnykBroker environment variables key-value pairs. PORT, BROKER\_CLIENT\_URL not required | `map(string)` | `{}` |   yes    |
| <a name="input_broker_hostname"></a> [broker\_hostname](#input\_broker\_hostname) | SnykBroker hostname. <broker\_hostname>.<public\_domain\_name> forms its FQDN for SCM webhooks calls | `string` | `"snykbroker"` |    no    |
| <a name="input_broker_port"></a> [broker\_port](#input\_broker\_port) | Default snykbroker client port. Set a non-system port i.e. >= 1024 as container run-as non-root user | `number` | `7341` |    no    |
| <a name="input_broker_private_key_object"></a> [broker\_private\_key\_object](#input\_broker\_private\_key\_object) | S3 object of SnykBroker certificate private key. Example <s3folder>/<name>.key | `string` | `null` |    no    |
| <a name="input_broker_protocol"></a> [broker\_protocol](#input\_broker\_protocol) | Protocol for running connections to SnykBroker. Either http or https | `string` | `"https"` |    no    |
| <a name="input_broker_ssl_cert_object"></a> [broker\_ssl\_cert\_object](#input\_broker\_ssl\_cert\_object) | S3 object of SnykBroker certificate. Example <s3folder>/<name>.pem | `string` | `null` |    no    |
| <a name="input_cloudwatch_log_group_name"></a> [cloudwatch\_log\_group\_name](#input\_cloudwatch\_log\_group\_name) | SnykBroker CloudWatch log group name | `string` | `"/aws/ecs/snykbroker"` |    no    |
| <a name="input_cloudwatch_log_retention_days"></a> [cloudwatch\_log\_retention\_days](#input\_cloudwatch\_log\_retention\_days) | SnykBroker CloudWatch log retention in days | `number` | `7` |    no    |
| <a name="input_config_bucket_name"></a> [config\_bucket\_name](#input\_config\_bucket\_name) | Configuration S3 bucket name storing SnykBroker private key, SSL certificate, accept.json filter, etc | `string` | `null` |    no    |
| <a name="input_container_name"></a> [container\_name](#input\_container\_name) | Snyk broker container name behind the Service | `string` | `"snykbroker"` |    no    |
| <a name="input_cpu"></a> [cpu](#input\_cpu) | Broker service task CPU. min 256 i.e. 0.25 vCPU, max 4096 i.e. 4 vCPU | `number` | `256` |    no    |
| <a name="input_custom_listing_filter"></a> [custom\_listing\_filter](#input\_custom\_listing\_filter) | Use custom approved listing filter i.e. a revised accept.json | `bool` | `false` |    no    |
| <a name="input_default_tags"></a> [default\_tags](#input\_default\_tags) | Default Tags at aws provider scope | `map(string)` | <pre>{<br>  "Snyk": "SnykBroker"<br>}</pre> |    no    |
| <a name="input_dockerhub_access_token"></a> [dockerhub\_access\_token](#input\_dockerhub\_access\_token) | DockerHub personal access token | `string` | `null` |    no    |
| <a name="input_dockerhub_username"></a> [dockerhub\_username](#input\_dockerhub\_username) | DockerHub username | `string` | `null` |    no    |
| <a name="input_fargate_capacity_base"></a> [fargate\_capacity\_base](#input\_fargate\_capacity\_base) | Fargate capacity provider base as minimum number of Tasks. Only this or fargate\_spot\_capacity\_base can be >0 | `number` | `0` |    no    |
| <a name="input_fargate_capacity_weight"></a> [fargate\_capacity\_weight](#input\_fargate\_capacity\_weight) | Fargate capacity provider weight as a relative percentage of total service\_desired\_count Tasks | `number` | `50` |    no    |
| <a name="input_fargate_spot_capacity_base"></a> [fargate\_spot\_capacity\_base](#input\_fargate\_spot\_capacity\_base) | Fargate Spot capacity provider base as minimum number of Tasks. Only this or fargate\_capacity\_base can be >0 | `number` | `0` |    no    |
| <a name="input_fargate_spot_capacity_weight"></a> [fargate\_spot\_capacity\_weight](#input\_fargate\_spot\_capacity\_weight) | Fargate Spot capacity provider weight as a relative percentage of total service\_desired\_count Tasks | `number` | `50` |    no    |
| <a name="input_image"></a> [image](#input\_image) | Broker image to pull from DockerHub. May be custom derived broker image | `string` | `null` |    no    |
| <a name="input_integration_type"></a> [integration\_type](#input\_integration\_type) | Snyk Integration type. Choice of artifactory, azurerepos, bitbucket, gh, ghe, gitlab, jira or nexus | `string` | `""` |   yes    |
| <a name="input_lambda_runtime"></a> [lambda\_runtime](#input\_lambda\_runtime) | Lambda function runtime. Defined by AWS supported versions. | `string` | `"python3.9"` |    no    |
| <a name="input_launch_type"></a> [launch\_type](#input\_launch\_type) | SnykBroker service launch type | `string` | `"FARGATE"` |    no    |
| <a name="input_log_bucket_name"></a> [log\_bucket\_name](#input\_log\_bucket\_name) | snykbbroker requests access log bucket name for logging webhooks requests | `string` | `null` |    no    |
| <a name="input_memory"></a> [memory](#input\_memory) | Broker service memory in MiB. Min 512, max 30720 | `number` | `512` |    no    |
| <a name="input_private_ssl_cert"></a> [private\_ssl\_cert](#input\_private\_ssl\_cert) | Use private SSL certificate at SnykBroker client | `bool` | `false` |    no    |
| <a name="input_public_domain_name"></a> [public\_domain\_name](#input\_public\_domain\_name) | Customer public domain e.g. example.com | `string` | `null` |   yes    |
| <a name="input_scheduling_strategy"></a> [scheduling\_strategy](#input\_scheduling\_strategy) | Snyk broker scheduling strategy | `string` | `"REPLICA"` |    no    |
| <a name="input_service_azs"></a> [service\_azs](#input\_service\_azs) | count of service availability zones to use | `number` | `2` |    no    |
| <a name="input_service_desired_count"></a> [service\_desired\_count](#input\_service\_desired\_count) | Snyk broker service instance count | `number` | `1` |    no    |
| <a name="input_service_name"></a> [service\_name](#input\_service\_name) | Snyk broker service name | `string` | `"snykbroker"` |    no    |
| <a name="input_snyk_integration_env_vars"></a> [snyk\_integration\_env\_vars](#input\_snyk\_integration\_env\_vars) | Map of Snyk integration type to environment values at the broker container | `map(list(string))` | <pre>{<br>  "artifactory": [<br>    "BROKER_TOKEN",<br>    "ARTIFACTORY_URL"<br>  ],<br>  "azurerepos": [<br>    "BROKER_TOKEN",<br>    "AZURE_REPOS_TOKEN",<br>    "AZURE_REPOS_ORG",<br>    "AZURE_REPOS_HOST",<br>    "PORT",<br>    "BROKER_CLIENT_URL"<br>  ],<br>  "bitbucket": [<br>    "BROKER_TOKEN",<br>    "BITBUCKET_USERNAME",<br>    "BITBUCKET_PASSWORD",<br>    "BITBUCKET",<br>    "BITBUCKET_API",<br>    "BROKER_CLIENT_URL",<br>    "PORT"<br>  ],<br>  "gh": [<br>    "BROKER_TOKEN",<br>    "GITHUB_TOKEN",<br>    "PORT",<br>    "BROKER_CLIENT_URL"<br>  ],<br>  "ghe": [<br>    "BROKER_TOKEN",<br>    "GITHUB_TOKEN",<br>    "GITHUB",<br>    "GITHUB_API",<br>    "GITHUB_GRAPHQL",<br>    "PORT",<br>    "BROKER_CLIENT_URL"<br>  ],<br>  "gitlab": [<br>    "BROKER_TOKEN",<br>    "GITLAB_TOKEN",<br>    "GITLAB",<br>    "PORT",<br>    "BROKER_CLIENT_URL"<br>  ],<br>  "jira": [<br>    "BROKER_TOKEN",<br>    "JIRA_USERNAME",<br>    "JIRA_PASSWORD",<br>    "JIRA_HOSTNAME",<br>    "BROKER_CLIENT_URL",<br>    "PORT"<br>  ],<br>  "nexus": [<br>    "BROKER_TOKEN",<br>    "BASE_NEXUS_URL",<br>    "BROKER_CLIENT_VALIDATION_URL",<br>    "RES_BODY_URL_SUB"<br>  ]<br>}</pre> |    no    |
| <a name="input_snyk_integration_images"></a> [snyk\_integration\_images](#input\_snyk\_integration\_images) | Map of Snyk integration type to default official Snyk Docker image tag | `map(string)` | <pre>{<br>  "artifactory": "artifactory",<br>  "azurerepos": "azure-repos",<br>  "bitbucket": "bitbucket-server",<br>  "gh": "github-com",<br>  "ghe": "github-enterprise",<br>  "gitlab": "gitlab",<br>  "jira": "jira",<br>  "nexus": "nexus"<br>}</pre> |    no    |
| <a name="input_snykbroker_repo"></a> [snykbroker\_repo](#input\_snykbroker\_repo) | DockerHub snyk broker repo | `string` | `"snyk/broker"` |    no    |
| <a name="input_tags"></a> [tags](#input\_tags) | Tags | `map(string)` | `{}` |    no    |
| <a name="input_use_existing_route53_zone"></a> [use\_existing\_route53\_zone](#input\_use\_existing\_route53\_zone) | Use existing public hosted zone of <public\_domain\_name> or create new zone | `bool` | `true` |    no    |
| <a name="input_vpc_cidr"></a> [vpc\_cidr](#input\_vpc\_cidr) | SnykBroker VPC cidr. Linked to service\_azs to be created | `string` | `"192.168.0.0/20"` |    no    |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_snykbroker_aws_dns_name"></a> [snykbroker\_aws\_dns\_name](#output\_snykbroker\_aws\_dns\_name) | SnykBroker Client AWS DNS name |
| <a name="output_snykbroker_client_healthcheck_url"></a> [snykbroker\_client\_healthcheck\_url](#output\_snykbroker\_client\_healthcheck\_url) | SnykBroker Client healthcheck URL |
| <a name="output_snykbroker_client_systemcheck_url"></a> [snykbroker\_client\_systemcheck\_url](#output\_snykbroker\_client\_systemcheck\_url) | SnykBroker Client systemcheck URL |
| <a name="output_snykbroker_lb_dns_name"></a> [snykbroker\_lb\_dns\_name](#output\_snykbroker\_lb\_dns\_name) | SnykBroker Client hosted domain DNS name |
<!-- END_TF_DOCS -->