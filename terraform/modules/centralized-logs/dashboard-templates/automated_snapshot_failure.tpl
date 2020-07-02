"type":"metric",
"properties": {
    "metrics": [
        [
            "AWS/ES",
            "AutomatedSnapshotFailure",
            "DomainName",
            "${domain_name}",
            "ClientId",
            "${client_id}"
        ]
    ],
    "period":60,
    "stat":"Maximum",
    "region":"${region}",
    "title":"${domain_name} automated snapshot failure"
}