# photo-recommender
A system that recommends photos based on previous photos you liked

This will be a horizontally-scalable version of https://github.com/euan-forrester/photo-recommender-poc, built to handle many users simultaneously.

I plan to use:
- Kubernetes: https://kubernetes.io/ and https://aws.amazon.com/eks/ 
- Kafka: https://kafka.apache.org/ and https://aws.amazon.com/msk/
- Clickhouse: https://clickhouse.yandex/
- Terraform: https://www.terraform.io/
- Ansible: https://www.ansible.com/
- Random other parts of AWS like ElastiCache, Parameter Store, CloudWatch, and Centralized Logging
- Vue.js: https://vuejs.org/

# Instructions

## AWS and terraform

First we need to create the infrastructure that the various parts of the system will run on

### Install terraform

```
brew install terraform
```

### Create an AWS account

Go to https://aws.amazon.com/ and click on "Create an AWS Account"

Then create an IAM user within that account. This user will need to have various permissions to create different kinds of infrastructure.

Copy the file `terraform/aws_credentials.example` to `terraform/aws_credentials` and copy the new user's AWS key and secret key into the new file you just created.

### Run terraform

Note that this will create infrastructure within your AWS account and could result in billing charges from AWS

```
cd terraform/puller-flickr/dev
terraform init
terraform plan
terraform apply
```

TODO:

- Move config over to AWS Parameter Store
- Autofill the elasticache endpoint/port into the appropriate parameter
- Consider putting security group(s) in terraform. How to specify user's IP address? .tfvars file?