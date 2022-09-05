![Snyk logo](https://snyk.io/style/asset/logo/snyk-print.svg)

# terraform-aws-snykbroker

Terraform reference example to create Snyk Broker as an AWS Elastic Container Service (ECS) Fargate Service.

## Usage

### Prerequisites
1. Create a S3 bucket to store deployment terraform state
2. Create GitHub repository **_dev_** environment
3. Modify `env/dev/config.s3.backend`
4. Modify `env/dev/terraform.tfvars`

### GitHub Action

This GitHub CI workflow (ci.yml) pipes input for running [Snyk broker](https://github.com/snyk/broker) and deploys necessary AWS resources running SnykBroker as a Fargate Service.

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

This Environment variable value is in HCL map(string). Example:
```
{"BROKER_TOKEN":"xxx","GITHUB_TOKEN":"yyy","PORT":"8000"}
```

### Command Line Interface method

The general steps are:

1. Configure S3 backend for terraform state
2. Setup Terraform input tfvars
3. Invoke the commands defined below to create the Fargate Service that launches corresponding SnykBroker dockerized container.
```
$ terraform init -backend-config="env/dev/config.s3.tfbackend"
$ terraform plan -input=false -var-file="env/dev/terraform.tfvars" -out=tfplan
$ terraform apply "tfplan"
```
