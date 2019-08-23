"type":"metric",
"properties": {
    "metrics": [
        [
            "AWS/ECS",
            "CPUUtilization",
            "ClusterName",
            "${cluster_name}"
        ],
        [
            "AWS/ECS",
            "CPUUtilization",
            "ClusterName",
            "${cluster_name}",
            "ServiceName",
            "puller-flickr-${environment}"
        ],
        [
            "AWS/ECS",
            "CPUUtilization",
            "ClusterName",
            "${cluster_name}",
            "ServiceName",
            "ingester-database-${environment}"
        ],
        [
            "AWS/ECS",
            "CPUUtilization",
            "ClusterName",
            "${cluster_name}",
            "ServiceName",
            "api-server-${environment}"
        ],
        [
            "AWS/ECS",
            "CPUUtilization",
            "ClusterName",
            "${cluster_name}",
            "ServiceName",
            "scheduler-${environment}"
        ],
        [
            "AWS/ECS",
            "CPUUtilization",
            "ClusterName",
            "${cluster_name}",
            "ServiceName",
            "puller-response-reader-${environment}"
        ]
    ],
    "period":300,
    "stat":"Average",
    "region":"${region}",
    "title":"ECS Cluster ${cluster_name} CPU"
}