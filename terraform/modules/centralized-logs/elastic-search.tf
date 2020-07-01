data "aws_caller_identity" "centralized_logs" {
  
}

resource "aws_security_group" "es_sg" {
  name        = "${var.elastic_search_domain_name}-sg"
  description = "Allow inbound traffic to ElasticSearch"
  vpc_id      = var.vpc_id

  ingress {
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_blocks = [
          var.local_machine_cidr
      ]
  }
}

resource "aws_cloudwatch_log_group" "elastic_search" {
    name = "elastic-search-${var.environment}"
}

resource "aws_cloudwatch_log_resource_policy" "example" {
    policy_name = "elastic-search-${var.environment}"

    policy_document = <<CONFIG
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "es.amazonaws.com"
      },
      "Action": [
        "logs:PutLogEvents",
        "logs:PutLogEventsBatch",
        "logs:CreateLogStream"
      ],
      "Resource": "arn:aws:logs:*"
    }
  ]
}
CONFIG
}

resource "aws_iam_service_linked_role" "es" {
  aws_service_name = "es.amazonaws.com"
}

resource "aws_elasticsearch_domain" "es" {
  domain_name           = var.elastic_search_domain_name
  elasticsearch_version = "7.4"
  
  encrypt_at_rest {
      enabled     = var.elastic_search_encryption_enabled
      kms_key_id  = var.elastic_search_encryption_enabled ? var.elastic_search_storage_encryption_kms_key_id : null
  }

  node_to_node_encryption {
      enabled     = var.elastic_search_encryption_enabled
  }

  cluster_config {
      zone_awareness_enabled    = var.elastic_search_multi_az

      instance_type             = var.elastic_search_instance_type
      instance_count            = var.elastic_search_instance_count
  
      dedicated_master_enabled  = var.elastic_search_dedicated_master_enabled
      dedicated_master_type     = var.elastic_search_dedicated_master_type
      dedicated_master_count    = var.elastic_search_dedicated_master_count

      #warm_enabled              = false # Maybe experiment with this later? # Not sure why terraform doesn't like this
  }

  #zone_awareness_config { # Not sure why terraform doesn't like this
  #    availability_zone_count = 2
  #}

  vpc_options {
      subnet_ids = var.elastic_search_subnet_ids
      security_group_ids = [
          aws_security_group.es_sg.id
      ]
  }

  ebs_options {
      ebs_enabled = true
      volume_size = var.elastic_search_ebs_volume_size
  }

  log_publishing_options {
      cloudwatch_log_group_arn = aws_cloudwatch_log_group.elastic_search.arn
      log_type                 = "INDEX_SLOW_LOGS"
  }

  log_publishing_options {
      cloudwatch_log_group_arn = aws_cloudwatch_log_group.elastic_search.arn
      log_type                 = "SEARCH_SLOW_LOGS"
  }

  access_policies = <<CONFIG
{
  "Version": "2012-10-17",
  "Statement": [
      {
          "Action": "es:*",
          "Principal": "*",
          "Effect": "Allow",
          "Resource": "arn:aws:es:${var.region}:${data.aws_caller_identity.centralized_logs.account_id}:domain/${var.elastic_search_domain_name}/*"
      }
  ]
}
  CONFIG

  snapshot_options {
      automated_snapshot_start_hour = 00
  }

  depends_on = [
      aws_iam_service_linked_role.es, # See https://www.terraform.io/docs/providers/aws/r/elasticsearch_domain.html: Must have service linked role to allow ES in VPC
  ]
}
