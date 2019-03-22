resource "aws_security_group" "kubernetes-cluster" {
  name        = "terraform-eks-${var.cluster_name}-cluster"
  description = "Cluster communication with worker nodes"
  vpc_id      = "${aws_vpc.kubernetes.id}"

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "terraform-eks-${var.cluster_name}"
  }
}

# OPTIONAL: Allow inbound traffic from your local workstation external IP
#           to the Kubernetes. You will need to replace A.B.C.D below with
#           your real IP. Services like icanhazip.com can help you find this.
resource "aws_security_group_rule" "kubernetes-cluster-ingress-local-machine-https" {
  cidr_blocks       = ["${var.local_machine_cidr}"]
  description       = "Allow local machine to communicate with the cluster API Server"
  from_port         = 443
  protocol          = "tcp"
  security_group_id = "${aws_security_group.kubernetes-cluster.id}"
  to_port           = 443
  type              = "ingress"
}
