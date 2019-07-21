"type":"metric",
"properties": {
    "metrics": [
        [
            "AWS/RDS",
            "FreeableMemory",
            "DBInstanceIdentifier",
            "${database_identifier}"
        ],
        [
            "AWS/RDS",
            "SwapUsage",
            "DBInstanceIdentifier",
            "${database_identifier}"
        ]
    ],
    "period":300,
    "stat":"Average",
    "region":"${region}",
    "title":"${database_identifier} database memory"
}