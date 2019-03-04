resource "aws_elasticache_cluster" "elasticache-puller-flickr" {
  cluster_id           = "puller-flickr-${var.environment}"
  engine               = "memcached"
  node_type            = "${var.memcached_node_type}"
  num_cache_nodes      = "${var.memcached_num_cache_nodes}"
  parameter_group_name = "default.memcached1.4"
  port                 = 11211
}