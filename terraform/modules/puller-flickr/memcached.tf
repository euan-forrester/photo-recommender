resource "aws_security_group" "elasticache" {
    name        = "terraform-elasticache-${var.environment}"
    description = "Allow communication with the memcached instance"
    vpc_id      = "${var.vpc_id}"

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

resource "aws_elasticache_subnet_group" "public_subnet_group" {
    name       = "public-elasticache-subnet-group-puller-flickr-memcached-${var.environment}"
    subnet_ids = ["${var.vpc_public_subnet_ids}"]
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
    subnet_group_name    = "${aws_elasticache_subnet_group.public_subnet_group.name}"
}