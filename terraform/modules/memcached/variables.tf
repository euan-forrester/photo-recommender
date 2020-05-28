variable "environment" {
}

variable "region" {
}

variable "vpc_id" {
}

variable "vpc_public_subnet_ids" {
  type = list(string)
}

variable "vpc_cidr" {
}

variable "memcached_node_type" {
}

variable "memcached_num_cache_nodes" {
}

variable "memcached_az_mode" {
}

