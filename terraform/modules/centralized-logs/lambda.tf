# IAM role stuff gotten from: https://docs.aws.amazon.com/AmazonCloudWatch/latest/logs/CWL_ES_Stream.html

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
  name            = "log-filter"
  log_group_name  = var.cloudwatch_log_group_name
  filter_pattern  = ""
  destination_arn = aws_lambda_function.cloudwatch-to-elasticsearch.arn

  depends_on      = [aws_lambda_permission.allow-cloudwatch] # https://stackoverflow.com/questions/38407660/terraform-configuring-cloudwatch-log-subscription-delivery-to-lambda/38428834#38428834
}

resource "aws_lambda_permission" "allow-cloudwatch" {
  statement_id  = "allow-cloudwatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.cloudwatch-to-elasticsearch.arn
  principal     = "logs.${var.region}.amazonaws.com"
  source_arn    = var.cloudwatch_log_group_arn
}

resource "aws_lambda_function" "cloudwatch-to-elasticsearch" {
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
}