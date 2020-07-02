"type":"metric",
"properties": {
    "metrics": [
        [
            "AWS/ES",
            "JVMMemoryPressure",
            "DomainName",
            "${domain_name}",
            "ClientId",
            "${client_id}"
        ],
        [
            "AWS/ES",
            "MasterJVMMemoryPressure",
            "DomainName",
            "${domain_name}",
            "ClientId",
            "${client_id}"
        ]
    ],
    "period":900,
    "stat":"Average",
    "region":"${region}",
    "title":"${domain_name} memory pressure"
}