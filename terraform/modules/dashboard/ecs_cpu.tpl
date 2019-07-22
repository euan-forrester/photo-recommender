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
            "database-ingester-${environment}"
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
        ]
    ],
    "period":300,
    "stat":"Average",
    "region":"${region}",
    "title":"ECS Cluster ${cluster_name} CPU"
}