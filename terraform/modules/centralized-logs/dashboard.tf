resource "aws_cloudwatch_dashboard" "main" {
  dashboard_name = "${var.application_name}-centralized-logs-${var.environment}"

  dashboard_body = <<EOF
  {
    "widgets": [
       {
          "x":0,
          "y":0,
          "width":24,
          "height":6,
          ${data.template_file.cluster_status.rendered}
       },
       {
          "x":0,
          "y":6,
          "width":8,
          "height":6,
          ${data.template_file.cpu_utilization.rendered}
       },
       {
          "x":8,
          "y":6,
          "width":8,
          "height":6,
          ${data.template_file.free_storage_space.rendered}
       },
       {
          "x":16,
          "y":6,
          "width":8,
          "height":6,
          ${data.template_file.jvm_memory_pressure.rendered}
       },
       {
          "x":0,
          "y":12,
          "width":8,
          "height":6,
          ${data.template_file.automated_snapshot_failure.rendered}
       },
       {
          "x":8,
          "y":12,
          "width":8,
          "height":6,
          ${data.template_file.index_writes_blocked.rendered}
       },
       {
          "x":16,
          "y":12,
          "width":8,
          "height":6,
          ${data.template_file.master_reachable.rendered}
       }   
    ]
  }
  
EOF

}

data "template_file" "cluster_status" {
  vars = {
    region      = var.region
    domain_name = var.elastic_search_domain_name
    client_id   = data.aws_caller_identity.centralized_logs.account_id
  }

  template = file("${path.module}/dashboard-templates/cluster_status.tpl")
}

data "template_file" "cpu_utilization" {
  vars = {
    region      = var.region
    domain_name = var.elastic_search_domain_name
    client_id   = data.aws_caller_identity.centralized_logs.account_id
  }

  template = file("${path.module}/dashboard-templates/cpu_utilization.tpl")
}

data "template_file" "free_storage_space" {
  vars = {
    region      = var.region
    domain_name = var.elastic_search_domain_name
    client_id   = data.aws_caller_identity.centralized_logs.account_id
  }

  template = file("${path.module}/dashboard-templates/free_storage_space.tpl")
}

data "template_file" "jvm_memory_pressure" {
  vars = {
    region      = var.region
    domain_name = var.elastic_search_domain_name
    client_id   = data.aws_caller_identity.centralized_logs.account_id
  }

  template = file("${path.module}/dashboard-templates/jvm_memory_pressure.tpl")
}

data "template_file" "automated_snapshot_failure" {
  vars = {
    region      = var.region
    domain_name = var.elastic_search_domain_name
    client_id   = data.aws_caller_identity.centralized_logs.account_id
  }

  template = file("${path.module}/dashboard-templates/automated_snapshot_failure.tpl")
}

data "template_file" "index_writes_blocked" {
  vars = {
    region      = var.region
    domain_name = var.elastic_search_domain_name
    client_id   = data.aws_caller_identity.centralized_logs.account_id
  }

  template = file("${path.module}/dashboard-templates/index_writes_blocked.tpl")
}

data "template_file" "master_reachable" {
  vars = {
    region      = var.region
    domain_name = var.elastic_search_domain_name
    client_id   = data.aws_caller_identity.centralized_logs.account_id
  }

  template = file("${path.module}/dashboard-templates/master_reachable.tpl")
}
