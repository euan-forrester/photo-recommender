"type":"metric",
"properties": {
    "metrics": [
        [
            "AWS/RDS",
            "NetworkTransmitThroughput",
            "DBInstanceIdentifier",
            "${database_identifier}"
        ],
        [
            "AWS/RDS",
            "NetworkReceiveThroughput",
            "DBInstanceIdentifier",
            "${database_identifier}"
        ],
        [
            "AWS/RDS",
            "WriteThroughput",
            "DBInstanceIdentifier",
            "${database_identifier}"
        ],
        [
            "AWS/RDS",
            "ReadThroughput",
            "DBInstanceIdentifier",
            "${database_identifier}"
        ]
    ],
    "period":300,
    "stat":"Average",
    "region":"${region}",
    "title":"${database_identifier} database I/O"
}