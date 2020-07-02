"type":"metric",
"properties": {
    "metrics": [
        [
            "AWS/ES",
            "ClusterIndexWritesBlocked",
            "DomainName",
            "${domain_name}",
            "ClientId",
            "${client_id}"
        ]
    ],
    "period":300,
    "stat":"Maximum",
    "region":"${region}",
    "title":"${domain_name} index writes blocked"
}