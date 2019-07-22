"type":"metric",
"properties": {
    "metrics": [
        [
            "AWS/EC2",
            "NetworkIn",
            "AutoScalingGroupName",
            "${autoscaling_group_name}"
        ],
        [
            "AWS/EC2",
            "NetworkOut",
            "AutoScalingGroupName",
            "${autoscaling_group_name}"
        ]
    ],
    "period":300,
    "stat":"Average",
    "region":"${region}",
    "title":"${autoscaling_group_name} network"
}