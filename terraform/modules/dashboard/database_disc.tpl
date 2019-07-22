"type":"metric",
"properties": {
    "metrics": [
        [
            "AWS/RDS",
            "FreeStorageSpace",
            "DBInstanceIdentifier",
            "${database_identifier}"
        ]
    ],
    "period":300,
    "stat":"Average",
    "region":"${region}",
    "title":"Database disc"
}