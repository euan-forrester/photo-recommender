# photo-recommender
A system that recommends photos based on previous photos you liked

This will be a horizontally-scalable version of https://github.com/euan-forrester/photo-recommender-poc, built to handle many users simultaneously.

Initially this will use the Flickr API, since it's the only one I know of where the API exposes lists of images that users favorited.

- imgur: looks like it has a similar API, but you have to be logged in as each user in order to see their favorites: https://api.imgur.com/endpoints/account
- Instagram: deprecated their API that allowed access to users' likes on Apr 4 2018: https://www.instagram.com/developer/changelog/
- Smugmug: I don't see any facility for adding favorites or getting them from the API: https://api.smugmug.com/api/v2/doc
- 500px: Their API is no longer free: https://support.500px.com/hc/en-us/articles/360002435653-API- Their API did appear to have the concept of "votes" which might be similar: https://github.com/500px/legacy-api-documentation/tree/master/endpoints/photo 
- Spotify: Is it possible to do something here with playlists? https://developer.spotify.com/documentation/web-api/
- YouPic: Seems to have a similar idea with favorites, and a somewhat similar idea with stars, although no public API that I see: https://youpic.com/faq

This project uses:

- Terraform: https://www.terraform.io/
- Elastic Container Service: https://aws.amazon.com/ecs/ and Elastic Container Registry: https://aws.amazon.com/ecr/
- SQS for the initial stab at data injestion, but consider changing to Kafka https://aws.amazon.com/msk/ or Kinesis https://aws.amazon.com/kinesis/
- RDS for the initial stab at data storage, but consider changing to Clickhouse: https://clickhouse.yandex/ or Redshift https://aws.amazon.com/redshift/
- A bunch of Python libs, most notably Flask and gunicorn
- ALB for load balancing: https://aws.amazon.com/elasticloadbalancing/
- S3 for serving static assets, CloudFront for routing requests, and Route53 for DNS
- CloudWatch for metrics & alarms, and a dashboard:  https://aws.amazon.com/cloudwatch/
- Random other parts of AWS like ElastiCache, Parameter Store, and Key Management Service
- Vue.js and friends for the frontend: https://vuejs.org/. The frontend project based on the Vue CLI: https://cli.vuejs.org/

# Instructions

## AWS and terraform

First we need to create the infrastructure that the various parts of the system will run on

### Install packages

```
brew install terraform
brew install mysql
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
- Fill in a master password for the various databases
- Fill in a 256-bit AES encryption key, used to encrypt user access tokens in the database. Can be obtained from https://www.allkeysgenerator.com/Random/Security-Encryption-Key-Generator.aspx for example

We specially encrypt these tokens because in dev we may want to have a small RDS instance for billing purposes that doesn't support encrypting the whole database, but it will still be storing real user access tokens.

You'll be able to ssh into any EC2 instances created with `ssh ec2-user@<public ip of instance>`

To kick the ECS service, ssh onto the instance you want to kick then type `sudo systemctl restart ecs`

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

## Manual steps to push our docker images to ECR

Install docker: https://docs.docker.com/install/

Install the AWS CLI: https://docs.aws.amazon.com/cli/latest/userguide/install-bundle.html

Copy `terraform/aws_credentials` to `~/.aws/credentials`

Log into your docker repository:

```
eval "$(aws ecr get-login --no-include-email --region us-west-2)"
```

Then build and push your image:

```
docker build -f ../../src/puller-flickr/Dockerfile ../../src
docker images
docker tag <ID of image you just built> <URI of puller-flickr-dev repository in ECR: use AWS console to find>
docker push <URI of puller-flicker-dev repository in ECR>
```

and again for the next images

```
docker build -f ../../src/puller-response-reader/Dockerfile ../../src
docker images
docker tag <ID of image you just built> <URI of puller-response-reader-dev repository in ECR: use AWS console to find>
docker push <URI of puller-response-reader-dev repository in ECR>
```

```
docker build -f ../../src/ingester-database/Dockerfile ../../src
docker images
docker tag <ID of image you just built> <URI of ingester-database-dev repository in ECR: use AWS console to find>
docker push <URI of ingester-database-dev repository in ECR>
```

```
docker build -f ../../src/ingester-response-reader/Dockerfile ../../src
docker images
docker tag <ID of image you just built> <URI of ingester-response-reader-dev repository in ECR: use AWS console to find>
docker push <URI of ingester-response-reader-dev repository in ECR>
```

```
docker build -f ../../src/api-server/Dockerfile ../../src
docker images
docker tag <ID of image you just built> <URI of api-server-dev repository in ECR: use AWS console to find>
docker push <URI of api-server-dev repository in ECR>
```

```
docker build -f ../../src/scheduler/Dockerfile ../../src
docker images
docker tag <ID of image you just built> <URI of scheduler-dev repository in ECR: use AWS console to find>
docker push <URI of scheduler-dev repository in ECR>
```

## Frontend setup

### Install packages

```
cd ../../frontend
brew install yarn
yarn install
```

### Optional project dashboard

```
yarn global add @vue/cli
vue ui
```

Then go to: http://localhost:8000/dashboard

### Deploy the frontend

Edit the bucket names in `frontend/vue.config.js` and `frontend/.env.production` to be the website s3 bucket(s) created by terraform if necessary. Similarly for the CloudFront IDs.

```
yarn build --mode development
yarn deploy --mode development
```

If you have a domain name, then go into route53 and point it at the nameservers listed there.
If you don't, then go into CloudFront to get the domain for our distribution. 

Point your browser there and enjoy!

TODO:

- Upgrade to terraform v0.12
- Make a build pipeline
- Consider moving MySQL passwords into config files rather than passing on command line from terraform script
- Add tests
- Look into how to lock versions of python dependencies of our dependencies (rather than just the packages we explicitly reference)
- Have the prod load balancer only listen on https
- Encrypt SQS messages in prod
- Use templating lib for outputting HTML from API server
- Centralize logging and make it searchable. Maybe like this: https://aws.amazon.com/solutions/centralized-logging/
- Make puller-flickr only get incremental updates since the last time it ran, rather than pulling all data every time
- Make puller-flickr look for deletions of favorites
- Investigate transaction usage in the batch database writer: what batch size should we use? is there a better transaction isolation level to use to help concurrency?
- Add auth to API server - use AWS API gateway?
- Audit for XSS attacks
- Add CSRF token
- Make frontend vendor file smaller (it's mostly bootstrap): https://bootstrap-vue.js.org/docs/#tree-shaking-with-module-bundlers
  - See also https://medium.com/js-dojo/how-to-reduce-your-vue-js-bundle-size-with-webpack-3145bf5019b7
- Add versioning to the front end, so that old versions of file (with different hashes) don't live in S3 forever: https://stackoverflow.com/questions/46166337/how-can-i-deploy-a-new-cloudfront-s3-version-without-a-small-period-of-unavailab?rq=1
- Get domain name + add hooks for google analytics
- Make batch messages for both types of response readers, rather than sending each message individually
- Have dismissed photos + users feed back into recommendations with negative scores
- Make visualization of how many instances of each process are doing work at a given time - send task ID to metics and get a count of distinct IDs?
- Have Scheduler ask for the number of seconds until the next user needs updating, then sleep for that long