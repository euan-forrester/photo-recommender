"type":"metric",
"properties": {
    "metrics": [
        [
            "AWS/SQS",
            "NumberOfMessagesSent",
            "QueueName",
            "${queue_full_name}"
        ],
        [
            "AWS/SQS",
            "NumberOfMessagesReceived",
            "QueueName",
            "${queue_full_name}"
        ],
        [
            "AWS/SQS",
            "ApproximateNumberOfMessagesVisible",
            "QueueName",
            "${queue_dead_letter_full_name}"
        ]
    ],
    "period":300,
    "stat":"Sum",
    "region":"${region}",
    "title":"${queue_base_name}"
}