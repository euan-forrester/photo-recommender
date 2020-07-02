"type":"metric",
"properties": {
    "metrics": [
        [
            "AWS/ES",
            "CPUUtilization",
            "DomainName",
            "${domain_name}",
            "ClientId",
            "${client_id}"
        ],
        [
            "AWS/ES",
            "MasterCPUUtilization",
            "DomainName",
            "${domain_name}",
            "ClientId",
            "${client_id}"
        ]
    ],
    "period":900,
    "stat":"Average",
    "region":"${region}",
    "title":"${domain_name} CPU"
}