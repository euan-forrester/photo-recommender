variable "environment" {
}

variable "region" {
}

variable "application_name" {
  
}

variable "centralized_logs_enabled" {
  type = bool
}

variable "alarms_sns_topic_arn" {

}

variable "enable_alarms" {

}

variable "vpc_id" {
  description = "VPC ID where to launch ElasticSearch cluster"
}

variable "local_machine_cidr" {
}

variable "elastic_search_domain_name" {
}

variable "elastic_search_subnet_ids" {
  type = list(string)
  description = "List of VPC Subnet IDs to create ElasticSearch Endpoints in"
}

variable "elastic_search_multi_az" {

}

variable "elastic_search_instance_type" {

}

variable "elastic_search_instance_count" {

}

variable "elastic_search_dedicated_master_enabled" {

}

variable "elastic_search_dedicated_master_type" {

}

variable "elastic_search_dedicated_master_count" {

}

variable "elastic_search_encryption_enabled" {
  type = bool
}

variable "elastic_search_storage_encryption_kms_key_id" {

}

variable "elastic_search_ebs_volume_size" {

}