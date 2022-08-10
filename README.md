# terraform-aws-snykbroker

Terraform example to create Snyk Broker as an AWS Elastic Container Service (ECS) Fargate Service.

### Usage

This workflow accepts inputs for running [Snyk broker](https://github.com/snyk/broker) and creates necessary AWS resources and runs SnykBroker as a Fargate Service.

Invoke the commands defined below to create the Fargate Service and launch the corresponding SnykBroker dockerized container.
```
$ terraform init
$ terraform plan -input=false -out=tfplan
$ terraform apply "tfplan"
```

### Inputs

The inputs to the IaC deployment comprise of GitHub configured secrets e.g. AWS, DockerHub credentials and Terraform variable values on the container specifications.

