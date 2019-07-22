"type":"metric",
"properties": {
    "metrics": [
        [
            "AWS/EC2",
            "CPUUtilization",
            "AutoScalingGroupName",
            "${autoscaling_group_name}"
        ]
    ],
    "period":300,
    "stat":"Average",
    "region":"${region}",
    "title":"${autoscaling_group_name} CPU"
}