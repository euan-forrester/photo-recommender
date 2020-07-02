"type":"metric",
"properties": {
    "metrics": [
        [
            "AWS/ES",
            "FreeStorageSpace",
            "DomainName",
            "${domain_name}",
            "ClientId",
            "${client_id}"
        ]
    ],
    "period":60,
    "stat":"Minimum",
    "region":"${region}",
    "title":"${domain_name} free storage space"
}