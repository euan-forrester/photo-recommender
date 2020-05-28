resource "aws_key_pair" "local_machine" {
  key_name   = "local_machine_${var.environment}"
  public_key = var.local_machine_public_key
}

resource "aws_launch_configuration" "ecs-launch-configuration" {
  name_prefix          = "ecs-launch-configuration-${var.cluster_name}-${var.environment}-" # Auto-generate the name because once it's created it can't be changed
  image_id             = "ami-0e5e051fd0b505db6"                                            # ECS-optimized image for us-west-2: https://docs.aws.amazon.com/AmazonECS/latest/developerguide/launch_container_instance.html
  instance_type        = var.instance_type
  iam_instance_profile = aws_iam_instance_profile.ecs-instance-profile.id

  root_block_device {
    volume_type           = "standard"
    volume_size           = 30
    delete_on_termination = true
  }

  lifecycle {
    create_before_destroy = true
  }

  security_groups             = concat(var.extra_security_groups, [aws_security_group.ecs.id])
  associate_public_ip_address = "true"
  key_name                    = aws_key_pair.local_machine.key_name
  user_data                   = <<EOF
                                  #!/bin/bash
                                  echo ECS_CLUSTER=${aws_ecs_cluster.ecs-cluster.name} >> /etc/ecs/ecs.config
                                  echo ECS_ENABLE_CONTAINER_METADATA=true >> /etc/ecs/ecs.config
                                  
EOF

}

resource "aws_autoscaling_group" "ecs-autoscaling-group" {
  name                 = "ecs-autoscaling-group-${var.cluster_name}-${var.environment}"
  max_size             = var.cluster_max_size
  min_size             = var.cluster_min_size
  desired_capacity     = var.cluster_desired_size
  vpc_zone_identifier  = var.vpc_public_subnet_ids
  launch_configuration = aws_launch_configuration.ecs-launch-configuration.name
  health_check_type    = "ELB"
}

resource "aws_ecs_cluster" "ecs-cluster" {
  name = "${var.cluster_name}-${var.environment}"
}

