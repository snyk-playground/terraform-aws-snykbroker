# terraform-aws-snykbroker

Terraform module to create Snyk Broker as an AWS Elastic Container Service (ECS) Fargate Service.

### Usage

This module accepts the inputs for running [Snyk broker](https://github.com/snyk/broker) and creates necessary AWS resources and runs SnykBroker as a Fargate Service.

```
module "snykbroker" {
  source = "github.com/gwnlng/terraform-aws-snykbroker"
  
  integration_type = "gh"
  broker_env_vars  = {
    "BROKER_TOKEN"      = "<broker_token_at_snyk_integration_settings>"
    "GITHUB_TOKEN"      = "<github_personal_access_token>"
    "PORT"              = "8000"
    "BROKER_CLIENT_URL" = "http://broker:8000"
  }
  "dockerhub_username" = "<dockerhub_username>"
  "dockerhub_access_token" = "<dockerhub_access_token>"
}
```
Invoke the commands defined below to create the Fargate Service and launch the corresponding SnykBroker dockerized container.
```
$ terraform init
$ terraform plan -out=tfplan
$ terraform apply "tfplan"
```