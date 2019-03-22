resource "aws_elasticache_cluster" "memcached" {
  cluster_id           = "puller-flickr-${var.environment}"
  engine               = "memcached"
  node_type            = "${var.memcached_node_type}"
  num_cache_nodes      = "${var.memcached_num_cache_nodes}"
  az_mode              = "${var.memcached_az_mode}"
  parameter_group_name = "default.memcached1.5"
  port                 = 11211
  security_group_ids   = ["sg-08635958ba3e140d7"] # FIXME: Create this security group with terraform and pass the ID here rather than hardcoding

  # Future note: There appears to be a bug in terraform 0.11 related to passing lists. If we pass in a list here, we get an error saying that the variable should be a string but got a list. If we need > 1 element here, we may need to pass in a string of comma-separated values, then split() it here. Or upgrade to terraform 0.12 when it's released: https://github.com/hashicorp/terraform/issues/13103. I couldn't get the workaround to work of passing in a list then having extra []'s here
}
