resource "aws_eks_cluster" "kubernetes" {
    name            = "${var.cluster_name}"
    role_arn        = "${aws_iam_role.kubernetes-cluster.arn}"

    vpc_config {
        security_group_ids = ["${aws_security_group.kubernetes-cluster.id}"]
        subnet_ids         = ["${aws_subnet.kubernetes.*.id}"]
    }

    depends_on = [
        "aws_iam_role_policy_attachment.kubernetes-cluster-AmazonEKSClusterPolicy",
        "aws_iam_role_policy_attachment.kubernetes-cluster-AmazonEKSServicePolicy",
    ]
}
