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