"type":"metric",
"properties": {
    "metrics": [
        [
            "AWS/RDS",
            "CPUUtilization",
            "DBInstanceIdentifier",
            "${database_identifier}"
        ]
    ],
    "period":300,
    "stat":"Average",
    "region":"${region}",
    "title":"${database_identifier} database CPU"
}