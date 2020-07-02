"type":"metric",
"properties": {
    "metrics": [
        [
            "AWS/ES",
            "ClusterStatus.green",
            "DomainName",
            "${domain_name}",
            "ClientId",
            "${client_id}",
            { "color": "#2ca02c" }
        ],
        [
            "AWS/ES",
            "ClusterStatus.yellow",
            "DomainName",
            "${domain_name}",
            "ClientId",
            "${client_id}",
            { "color": "#ff7f0e" }
        ],
        [
            "AWS/ES",
            "ClusterStatus.red",
            "DomainName",
            "${domain_name}",
            "ClientId",
            "${client_id}",
            { "color": "#d62728" }
        ]
    ],
    "period":60,
    "stat":"Maximum",
    "region":"${region}",
    "title":"${domain_name} cluster status"
}