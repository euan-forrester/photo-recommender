resource "aws_cloudwatch_dashboard" "main" {
  dashboard_name = "photo-recommender-${var.environment}"

  dashboard_body = <<EOF
  {
    "widgets": [
       {
          "x":0,
          "y":0,
          "width":24,
          "height":6,
          ${data.template_file.time_to_get_all_data.rendered}
       },
       {
          "x":0,
          "y":6,
          "width":12,
          "height":6,
          ${data.template_file.puller_queue.rendered}
       },
       {
          "x":12,
          "y":6,
          "width":6,
          "height":6,
          ${data.template_file.puller_response_queue.rendered}
       },
       {
          "x":18,
          "y":6,
          "width":6,
          "height":6,
          ${data.template_file.ingester_response_queue.rendered}
       },
       {
          "x":0,
          "y":12,
          "width":12,
          "height":6,
          ${data.template_file.ingester_queue.rendered}
       },
       {
          "x":12,
          "y":12,
          "width":6,
          "height":6,
          ${data.template_file.ec2_network.rendered} 
       },
       {
          "x":18,
          "y":12,
          "width":6,
          "height":6,
          ${data.template_file.ec2_cpu.rendered} 
       },
       {
          "x":0,
          "y":18,
          "width":12,
          "height":6,
          ${data.template_file.database_io.rendered} 
       },
       {
          "x":12,
          "y":18,
          "width":4,
          "height":6,
          ${data.template_file.database_cpu.rendered} 
       },
       {
          "x":16,
          "y":18,
          "width":4,
          "height":6,
          ${data.template_file.database_disc.rendered} 
       },
       {
          "x":20,
          "y":18,
          "width":4,
          "height":6,
          ${data.template_file.database_memory.rendered} 
       },
       {
          "x":0,
          "y":24,
          "width":12,
          "height":6,
          ${data.template_file.ecs_cpu.rendered} 
       },
       {
          "x":12,
          "y":24,
          "width":12,
          "height":6,
          ${data.template_file.ecs_memory.rendered} 
       },
       {
          "x":0,
          "y":30,
          "width":12,
          "height":6,
          ${data.template_file.unhandled_exceptions.rendered} 
       },
       {
          "x":12,
          "y":30,
          "width":12,
          "height":6,
          ${data.template_file.timing.rendered} 
       }
    ]
  }
  EOF
}

data "template_file" "time_to_get_all_data" {
    vars = {
        title                       = "Time to get all data"
        environment                 = "${var.environment}"
        process_name                = "ingester-response-reader"
        metric_name                 = "time_to_get_all_data"
        region                      = "${var.region}"
    }

    template = "${file("${path.module}/generic_metric.tpl")}"
}

data "template_file" "puller_queue" {
    vars = {
        queue_full_name             = "${var.puller_queue_full_name}"
        queue_base_name             = "${var.puller_queue_base_name}"
        queue_dead_letter_full_name = "${var.puller_queue_dead_letter_full_name}"
        region                      = "${var.region}"
    }

    template = "${file("${path.module}/sqs_queue.tpl")}"
}

data "template_file" "puller_response_queue" {
    vars = {
        queue_full_name             = "${var.puller_response_queue_full_name}"
        queue_base_name             = "${var.puller_response_queue_base_name}"
        queue_dead_letter_full_name = "${var.puller_response_queue_dead_letter_full_name}"
        region                      = "${var.region}"
    }

    template = "${file("${path.module}/sqs_queue.tpl")}"
}

data "template_file" "ingester_queue" {
    vars = {
        queue_full_name             = "${var.ingester_queue_full_name}"
        queue_base_name             = "${var.ingester_queue_base_name}"
        queue_dead_letter_full_name = "${var.ingester_queue_dead_letter_full_name}"
        region                      = "${var.region}"
    }

    template = "${file("${path.module}/sqs_queue.tpl")}"
}

data "template_file" "ingester_response_queue" {
    vars = {
        queue_full_name             = "${var.ingester_response_queue_full_name}"
        queue_base_name             = "${var.ingester_response_queue_base_name}"
        queue_dead_letter_full_name = "${var.ingester_response_queue_dead_letter_full_name}"
        region                      = "${var.region}"
    }

    template = "${file("${path.module}/sqs_queue.tpl")}"
}

data "template_file" "ec2_network" {
    vars = {
        autoscaling_group_name      = "${var.ecs_autoscaling_group_name}"
        region                      = "${var.region}"
    }

    template = "${file("${path.module}/ec2_network.tpl")}"
}

data "template_file" "ec2_cpu" {
    vars = {
        autoscaling_group_name      = "${var.ecs_autoscaling_group_name}"
        region                      = "${var.region}"
    }

    template = "${file("${path.module}/ec2_cpu.tpl")}"
}

data "template_file" "database_io" {
    vars = {
        database_identifier         = "${var.database_identifier}"
        region                      = "${var.region}"
    }

    template = "${file("${path.module}/database_io.tpl")}"
}

data "template_file" "database_cpu" {
    vars = {
        database_identifier         = "${var.database_identifier}"
        region                      = "${var.region}"
    }

    template = "${file("${path.module}/database_cpu.tpl")}"
}

data "template_file" "database_disc" {
    vars = {
        database_identifier         = "${var.database_identifier}"
        region                      = "${var.region}"
    }

    template = "${file("${path.module}/database_disc.tpl")}"
}

data "template_file" "database_memory" {
    vars = {
        database_identifier         = "${var.database_identifier}"
        region                      = "${var.region}"
    }

    template = "${file("${path.module}/database_memory.tpl")}"
}

data "template_file" "ecs_cpu" {
    vars = {
        cluster_name                = "${var.ecs_cluster_name}"
        region                      = "${var.region}"
        environment                 = "${var.environment}"
    }

    template = "${file("${path.module}/ecs_cpu.tpl")}"
}

data "template_file" "ecs_memory" {
    vars = {
        cluster_name                = "${var.ecs_cluster_name}"
        region                      = "${var.region}"
        environment                 = "${var.environment}"
    }

    template = "${file("${path.module}/ecs_memory.tpl")}"
}

data "template_file" "unhandled_exceptions" {
    vars = {
        title                       = "Unhandled exceptions"
        environment                 = "${var.environment}"
        metrics_namespace           = "${var.metrics_namespace}"
        metric_name                 = "UnhandledException"
        region                      = "${var.region}"
    }

    template = "${file("${path.module}/unhandled_exceptions.tpl")}"
}

data "template_file" "timing" {
    vars = {
        title                       = "Timing"
        environment                 = "${var.environment}"
        metrics_namespace           = "${var.metrics_namespace}"
        region                      = "${var.region}"
    }

    template = "${file("${path.module}/timing.tpl")}"
}