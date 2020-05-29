output "location" {
  # Ugly syntax here for referencing a resource that may not exist. See https://github.com/hashicorp/terraform/issues/16726
  # With terraform 0.12 we could use their new short-circuiting conditional logic to simplify this expression, since we wouldn't 
  # run into an issue anymore of having the conditional reference a resource that wasn't created. However, that would mean putting the test
  # that determines whether the resource is created or not in two places. So this method seems more rebust even though it's harder to read.
  #
  # Puts "localhost:11211" in this attribute if the memcached cluster wasn't created. The script will attempt to connect to there, fail, and continue in that case
  
  value = format(
    "%s:%d",
    element(
      concat(
        aws_elasticache_cluster.memcached.*.cluster_address,
        ["localhost"],
      ),
      0,
    ),
    element(
      concat(aws_elasticache_cluster.memcached.*.port, [11211]),
      0,
    ),
  )

  description = "Connection string for the memcached cluster created (or 'localhost:11211' if it was not created)"
}

