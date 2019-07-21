resource "aws_cloudwatch_dashboard" "main" {
  dashboard_name = "photo-recommender-${var.environment}"

  dashboard_body = <<EOF
  {
    "widgets": [
       {
          "x":0,
          "y":0,
          "width":12,
          "height":6,
          ${data.template_file.scheduler_queue.rendered}
       },
       {
          "x":12,
          "y":0,
          "width":12,
          "height":6,
          ${data.template_file.scheduler_response_queue.rendered}
       },
       {
          "x":0,
          "y":6,
          "width":12,
          "height":6,
          ${data.template_file.ingester_queue.rendered}
       },
       {
          "x":0,
          "y":12,
          "width":12,
          "height":6,
          ${data.template_file.database_io.rendered} 
       },
       {
          "x":12,
          "y":12,
          "width":4,
          "height":6,
          ${data.template_file.database_cpu.rendered} 
       },
       {
          "x":16,
          "y":12,
          "width":4,
          "height":6,
          ${data.template_file.database_disc.rendered} 
       },
       {
          "x":20,
          "y":12,
          "width":4,
          "height":6,
          ${data.template_file.database_memory.rendered} 
       }
    ]
  }
  EOF
}

data "template_file" "scheduler_queue" {
    vars = {
        queue_full_name             = "${var.scheduler_queue_full_name}"
        queue_base_name             = "${var.scheduler_queue_base_name}"
        queue_dead_letter_full_name = "${var.scheduler_queue_dead_letter_full_name}"
        region                      = "${var.region}"
    }

    template = "${file("${path.module}/sqs_queue.tpl")}"
}

data "template_file" "scheduler_response_queue" {
    vars = {
        queue_full_name             = "${var.scheduler_response_queue_full_name}"
        queue_base_name             = "${var.scheduler_response_queue_base_name}"
        queue_dead_letter_full_name = "${var.scheduler_response_queue_dead_letter_full_name}"
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