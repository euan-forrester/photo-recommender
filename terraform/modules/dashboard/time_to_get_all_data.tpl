"type":"metric",
"properties": {
    "metrics": [
        [
            "Photo Recommender",
            "time_to_get_all_data",
            "Environment",
            "${environment}",
            "Process",
            "ingester-response-reader"
        ],
        [
            "Photo Recommender",
            "time_to_get_all_data",
            "Environment",
            "${environment}",
            "Process",
            "puller-response-reader"
        ]
    ],
    "period":300,
    "stat":"Average",
    "region":"${region}",
    "title":"Time to get all data"
}