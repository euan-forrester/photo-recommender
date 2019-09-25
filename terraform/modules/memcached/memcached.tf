resource "aws_security_group" "elasticache" {
    name        = "memcached-${var.environment}"
    description = "Allow communication with the memcached instance"
    vpc_id      = "${var.vpc_id}"

    tags = {
        Name = "terraform-elasticache-${var.environment}"
    }
}

resource "aws_security_group_rule" "elasticache" {
    cidr_blocks       = ["${var.vpc_cidr}"]
    description       = "Allow EC2 instances to communicate with the memcached instance"
    from_port         = 11211
    protocol          = "tcp"
    security_group_id = "${aws_security_group.elasticache.id}"
    to_port           = 11211
    type              = "ingress"
}

resource "aws_elasticache_subnet_group" "subnet_group" {
    name       = "elasticache-subnet-group-memcached-${var.environment}"
    subnet_ids = ["${var.vpc_public_subnet_ids}"]
}

resource "aws_elasticache_cluster" "memcached" {
    count                = "${var.memcached_num_cache_nodes != 0 ? 1 : 0}" # Don't create the resource at all if we specify 0 nodes. See https://itnext.io/things-i-wish-i-knew-about-terraform-before-jumping-into-it-43ee92a9dd65

    cluster_id           = "memcached-${var.environment}"
    engine               = "memcached"
    node_type            = "${var.memcached_node_type}"
    num_cache_nodes      = "${var.memcached_num_cache_nodes}"
    az_mode              = "${var.memcached_az_mode}"
    parameter_group_name = "default.memcached1.5"
    port                 = 11211
    security_group_ids   = ["${aws_security_group.elasticache.id}"]
    subnet_group_name    = "${aws_elasticache_subnet_group.subnet_group.name}"
}