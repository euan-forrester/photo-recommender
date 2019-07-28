"type":"metric",
"properties": {
    "metrics": [
        [
            "Photo Recommender",
            "${metric_name}",
            "Environment",
            "${environment}",
            "Process",
            "api-server"
        ],
        [
            "Photo Recommender",
            "${metric_name}",
            "Environment",
            "${environment}",
            "Process",
            "scheduler"
        ],
        [
            "Photo Recommender",
            "${metric_name}",
            "Environment",
            "${environment}",
            "Process",
            "puller-flickr"
        ],
        [
            "Photo Recommender",
            "${metric_name}",
            "Environment",
            "${environment}",
            "Process",
            "ingester-database"
        ]

    ],
    "period":300,
    "stat":"Sum",
    "region":"${region}",
    "title":"${title}"
}