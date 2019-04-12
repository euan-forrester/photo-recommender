# photo-recommender
A system that recommends photos based on previous photos you liked

This will be a horizontally-scalable version of https://github.com/euan-forrester/photo-recommender-poc, built to handle many users simultaneously.

Initially this will use the Flickr API, since it's the only one I know of where the API exposes lists of images that users favorited.

- imgur: looks like it has a similar API, but you have to be logged in as each user in order to see their favorites: https://api.imgur.com/endpoints/account
- Instagram: deprecated their API that allowed access to users' likes on Apr 4 2018: https://www.instagram.com/developer/changelog/
- Smugmug: I don't see any facility for adding favorites or getting them from the API: https://api.smugmug.com/api/v2/doc
- 500px: Their API is no longer free: https://support.500px.com/hc/en-us/articles/360002435653-API- Their API did appear to have the concept of "votes" which might be similar: https://github.com/500px/legacy-api-documentation/tree/master/endpoints/photo 

I plan to use:
- Terraform: https://www.terraform.io/
- Elastic Container Service: https://aws.amazon.com/ecs/ and Elastic Container Registry: https://aws.amazon.com/ecr/
- CodeBuild: https://aws.amazon.com/codebuild/
- SQS for the initial stab at data injestion, but consider changing to Kafka https://aws.amazon.com/msk/ or Kinesis https://aws.amazon.com/kinesis/
- RDS for the initial stab at data storage, but consider changing to Clickhouse: https://clickhouse.yandex/ or Redshift https://aws.amazon.com/redshift/
- Random other parts of AWS like ElastiCache, Parameter Store, CloudWatch. and Key Management Service
- Maybe building a fancy Centralized Logging thing: https://aws.amazon.com/solutions/centralized-logging/
- Vue.js: https://vuejs.org/

# Instructions

## AWS and terraform

First we need to create the infrastructure that the various parts of the system will run on

### Install packages

```
brew install terraform
```

### Create an AWS account

Go to https://aws.amazon.com/ and click on "Create an AWS Account"

Then create an IAM user within that account. This user will need to have various permissions to create different kinds of infrastructure.

Copy the file `terraform/aws_credentials.example` to `terraform/aws_credentials`
- Copy the new user's AWS key and secret key into the new file you just created.

Copy the file `terraform/terraform.tfvars.example` to `terraform/terraform.tfvars` 
- Enter the CIDR of your local machine/network
- Copy your ssh public key (contained in `~/.ssh/id_rsa.pub`. If that file doesn't exist, run `ssh-keygen -t rsa` to generate it)
- Fill in your Flickr API key and secret: https://www.flickr.com/services/apps/create/apply
- Fill in your numerical Flickr user ID. You may need to get your numerical ID from: http://idgettr.com/

### Run terraform

Note that this will create infrastructure within your AWS account and could result in billing charges from AWS

Note: Run terraform with the environment variable `TF_LOG=1` to help debug permissions issues.

For convenience we will create a symlink to our `terraform.tfvars` file. You can also import these variables from the command line when you run terraform if you prefer.

```
cd terraform/dev
ln -s ../terraform.tfvars terraform.tfvars
terraform init
terraform plan
terraform apply
```

## Manual steps to push our docker image to ECR

Install docker: https://docs.docker.com/install/

Install the AWS CLI: https://docs.aws.amazon.com/cli/latest/userguide/install-bundle.html

Copy `terraform/aws_credentials` to `~/.aws/credentials`

Log into your docker repository:

```
eval "$(aws ecr get-login --no-include-email --region us-west-2)"
```

Then build and push your image:

```
docker build -f ../../puller-flickr/Dockerfile ../..
docker images
docker tag <ID of image you just built> <URI of puller-flickr-dev repository in ECR: use AWS console to find>
docker push <URI of puller-flicker-dev repository in ECR>
```

TODO:

- Have ECS running in > 1 availability zone (see examples in the links in the README in the elastic-container-service module)
- Make a build pipeline
