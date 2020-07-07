# IAM role stuff gotten from: https://docs.aws.amazon.com/AmazonCloudWatch/latest/logs/CWL_ES_Stream.html

# Terraform based on https://stackoverflow.com/questions/38407660/terraform-configuring-cloudwatch-log-subscription-delivery-to-lambda

resource "aws_iam_role" "cloudwatch-lambda-role" {
  name = "cloudwatch-lambda-role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "cloudwatch-lambda-policy" {
  name = "cloudwatch-lambda-policy"
  role = aws_iam_role.cloudwatch-lambda-role.id

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Action": [
                "es:*"
            ],
            "Effect": "Allow",
            "Resource": "arn:aws:es:${var.region}:${data.aws_caller_identity.centralized_logs.account_id}:domain/${var.elastic_search_domain_name}/*"
        }
    ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "attach-vpc-access" {
  role       = aws_iam_role.cloudwatch-lambda-role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}

resource "aws_cloudwatch_log_subscription_filter" "log-filter" {
  count           = var.centralized_logs_enabled ? 1 : 0

  name            = "log-filter"
  log_group_name  = var.cloudwatch_log_group_name
  filter_pattern  = ""
  destination_arn = aws_lambda_function.cloudwatch-to-elasticsearch[count.index].arn

  depends_on      = [aws_lambda_permission.allow-cloudwatch] # https://stackoverflow.com/questions/38407660/terraform-configuring-cloudwatch-log-subscription-delivery-to-lambda/38428834#38428834
}

resource "aws_lambda_permission" "allow-cloudwatch" {
  count           = var.centralized_logs_enabled ? 1 : 0

  statement_id  = "allow-cloudwatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.cloudwatch-to-elasticsearch[count.index].arn
  principal     = "logs.${var.region}.amazonaws.com"
  source_arn    = var.cloudwatch_log_group_arn
}

resource "aws_security_group" "cloudwatch-lambda-elasticsearch" {
  name = "cloudwatch-lambda"

  description = "Security group for lambda to move logs from Cloud Watch Logs to ElasticSearch"
  vpc_id      = var.vpc_id

  egress {
    from_port = 443
    to_port   = 443
    protocol  = "tcp"
    cidr_blocks = [
      "0.0.0.0/0",
    ]
  }
}

resource "aws_cloudwatch_log_group" "cloudwatch-to-elasticsearch" {
  name              = "/aws/lambda/cloudwatch-to-elasticsearch"
  retention_in_days = var.lamba_log_retention_days
}

resource "aws_lambda_function" "cloudwatch-to-elasticsearch" {
  count         = var.centralized_logs_enabled ? 1 : 0

  description   = "CloudWatch Logs to Amazon ES streaming"
  filename      = "${path.module}/lambda-src/cloudwatch-to-elasticsearch.zip"
  function_name = "cloudwatch-to-elasticsearch"
  role          = aws_iam_role.cloudwatch-lambda-role.arn
  handler       = "cloudwatch-to-elasticsearch.handler"
  source_code_hash = filebase64sha256("${path.module}/lambda-src/cloudwatch-to-elasticsearch.zip")

  runtime = "nodejs10.x"
  timeout = 60 # 1 minute
  memory_size = 128 # MB

  environment {
    variables = {
      ELASTIC_SEARCH_ENDPOINT = aws_elasticsearch_domain.es.endpoint
    }
  }

  vpc_config {
    subnet_ids         = var.elastic_search_subnet_ids
    security_group_ids = [aws_security_group.cloudwatch-lambda-elasticsearch.id]
  }

  depends_on = [
    aws_cloudwatch_log_group.cloudwatch-to-elasticsearch # The logs get put into the log group whose name matches ours, so we need to set an explicit dependency:  https://www.terraform.io/docs/providers/aws/r/lambda_function.html#cloudwatch-logging-and-permissions
  ]
}