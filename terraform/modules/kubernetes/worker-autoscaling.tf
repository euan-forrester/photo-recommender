data "aws_ami" "eks-worker" {
  filter {
    name   = "name"
    values = ["amazon-eks-node-${aws_eks_cluster.kubernetes.version}-v*"]
  }

  most_recent = true
  owners      = ["602401143452"] # Amazon EKS AMI Account ID
}

# EKS currently documents this required userdata for EKS worker nodes to
# properly configure Kubernetes applications on the EC2 instance.
# We utilize a Terraform local here to simplify Base64 encoding this
# information into the AutoScaling Launch Configuration.
# More information: https://docs.aws.amazon.com/eks/latest/userguide/launch-workers.html
locals {
  kubernetes-node-userdata = <<USERDATA
#!/bin/bash
set -o xtrace
/etc/eks/bootstrap.sh --apiserver-endpoint '${aws_eks_cluster.kubernetes.endpoint}' --b64-cluster-ca '${aws_eks_cluster.kubernetes.certificate_authority.0.data}' '${var.cluster_name}'
USERDATA
}

resource "aws_launch_configuration" "kubernetes" {
  associate_public_ip_address = true
  iam_instance_profile        = "${aws_iam_instance_profile.kubernetes-node.name}"
  image_id                    = "${data.aws_ami.eks-worker.id}"
  instance_type               = "${var.node_type}"
  name_prefix                 = "terraform-eks-kubernetes"
  security_groups             = ["${aws_security_group.kubernetes-node.id}"]
  user_data_base64            = "${base64encode(local.kubernetes-node-userdata)}"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "kubernetes" {
  desired_capacity     = 2
  launch_configuration = "${aws_launch_configuration.kubernetes.id}"
  max_size             = 2
  min_size             = 1
  name                 = "terraform-eks-kubernetes"
  vpc_zone_identifier  = ["${aws_subnet.kubernetes.*.id}"]

  tag {
    key                 = "Name"
    value               = "terraform-eks-kubernetes"
    propagate_at_launch = true
  }

  tag {
    key                 = "kubernetes.io/cluster/${var.cluster_name}"
    value               = "owned"
    propagate_at_launch = true
  }
}
