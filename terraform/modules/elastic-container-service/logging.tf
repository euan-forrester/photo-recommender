data "aws_caller_identity" "logging" {
}

# NOTE: See https://docs.aws.amazon.com/AmazonCloudWatch/latest/logs/encrypt-log-data-kms.html
resource "aws_kms_key" "logs" {
  description             = "Used to encrypt/decrypt logs"
  key_usage               = "ENCRYPT_DECRYPT"
  enable_key_rotation     = true
  deletion_window_in_days = 30
  policy                  = <<POLICY
{
  "Version" : "2012-10-17",
  "Id" : "key-default-1",
  "Statement" : [ {
      "Sid" : "Enable IAM User Permissions",
      "Effect" : "Allow",
      "Principal" : {
        "AWS" : "arn:aws:iam::${data.aws_caller_identity.logging.account_id}:root"
      },
      "Action" : "kms:*",
      "Resource" : "*"
    },
    {
      "Effect": "Allow",
      "Principal": { "Service": "logs.${var.region}.amazonaws.com" },
      "Action": [ 
        "kms:Encrypt*",
        "kms:Decrypt*",
        "kms:ReEncrypt*",
        "kms:GenerateDataKey*",
        "kms:Describe*"
      ],
      "Resource": "*"
    }  
  ]
}
    
POLICY

}

resource "aws_cloudwatch_log_group" "log_group" {
  name              = "${var.cluster_name}-${var.environment}"
  retention_in_days = var.instances_log_retention_days
  kms_key_id        = aws_kms_key.logs.arn
}

# Part of a task definition, used in task-definition.tf
# TODO: Consider sending all logs to a single region so they can all be viewed together
data "template_file" "log_configuration" {
  template = <<EOF
    "logConfiguration": {
      "logDriver": "awslogs",
      "options": {
        "awslogs-datetime-format": "%Y-%m-%d %H:%M:%S.%f %z",
        "awslogs-region": "${var.region}",
        "awslogs-group": "${aws_cloudwatch_log_group.log_group.name}",
        "awslogs-stream-prefix": "${var.cluster_name}"
      }
    }
EOF

}

