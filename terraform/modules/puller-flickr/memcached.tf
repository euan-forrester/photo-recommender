resource "aws_default_vpc" "default" {

}

resource "aws_security_group" "elasticache" {
    name        = "terraform-elasticache-${var.environment}"
    description = "Allow communication with the memcached instance"
    vpc_id      = "${aws_default_vpc.default.id}"

    tags = {
        Name = "terraform-elasticache-${var.environment}"
    }
}

resource "aws_security_group_rule" "elasticache-local-machine" {
    cidr_blocks       = ["${var.local_machine_cidr}"]
    description       = "Allow local machine to communicate with the memcached instance"
    from_port         = 11211
    protocol          = "tcp"
    security_group_id = "${aws_security_group.elasticache.id}"
    to_port           = 11211
    type              = "ingress"
}

resource "aws_elasticache_cluster" "memcached" {
    cluster_id           = "puller-flickr-${var.environment}"
    engine               = "memcached"
    node_type            = "${var.memcached_node_type}"
    num_cache_nodes      = "${var.memcached_num_cache_nodes}"
    az_mode              = "${var.memcached_az_mode}"
    parameter_group_name = "default.memcached1.5"
    port                 = 11211
    security_group_ids   = ["${aws_security_group.elasticache.id}"]
}