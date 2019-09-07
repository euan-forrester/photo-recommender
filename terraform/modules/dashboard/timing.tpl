"type":"metric",
"properties": {
    "metrics": [
        [
            "Photo Recommender",
            "duration_to_process_user",
            "Environment",
            "${environment}",
            "Process",
            "puller-flickr"
        ],
        [
            "Photo Recommender",
            "duration_to_get_favorites_from_flickr",
            "Environment",
            "${environment}",
            "Process",
            "puller-flickr"
        ],
        [
            "Photo Recommender",
            "duration_to_get_contacts_from_flickr",
            "Environment",
            "${environment}",
            "Process",
            "puller-flickr"
        ],
        [
            "Photo Recommender",
            "flickr_api_retries",
            "Environment",
            "${environment}",
            "Process",
            "puller-flickr"
        ],
        [
            "Photo Recommender",
            "FlickrApiException",
            "Environment",
            "${environment}",
            "Process",
            "puller-flickr"
        ],
        [
            "Photo Recommender",
            "database_favorites_write_duration",
            "Environment",
            "${environment}",
            "Process",
            "ingester-database"
        ],
        [
            "Photo Recommender",
            "database_contacts_write_duration",
            "Environment",
            "${environment}",
            "Process",
            "ingester-database"
        ]

    ],
    "period":300,
    "stat":"Maximum",
    "region":"${region}",
    "title":"${title}"
}