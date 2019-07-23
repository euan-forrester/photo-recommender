output "location" {
    # Ugly syntax here for referencing a resource that may not exist. See https://github.com/hashicorp/terraform/issues/16726
    # Puts "localhost:11211" in this attribute if the memcached cluster wasn't created. The script will attempt to connect to there, fail, and continue in that case
    # Also note that all variables are internally stored as strings, so having the port as an int results in a strange error message: https://github.com/hashicorp/terraform/issues/17033
    value       = "${format("%s:%s", element(concat(aws_elasticache_cluster.memcached.*.cluster_address, list("localhost")), 0), element(concat(aws_elasticache_cluster.memcached.*.port, list("11211")), 0))}"

    description = "Connection string for the memcached cluster created (or 'localhost:11211' if it was not created)"
}