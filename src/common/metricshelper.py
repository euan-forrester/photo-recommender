import boto3

class MetricsHelper:

    '''
    Wraps the functionality of sending metrics to CloudWatch
    '''

    def __init__(self, environment, process_name, metrics_namespace):
        self.environment        = environment
        self.process_name       = process_name
        self.metrics_namespace  = metrics_namespace
        self.cloudwatch         = boto3.client('cloudwatch') # Region is read from the AWS_DEFAULT_REGION env var
   
    def send_time(self, metric_name, time_in_seconds):
        self._send_metric(metric_name, time_in_seconds, "Seconds")

    def increment_count(self, metric_name, inc_amount=1):
        self._send_metric(metric_name, inc_amount, "Count")

    def _send_metric(self, metric_name, value, units):

        response = self.cloudwatch.put_metric_data(
            MetricData = [
                {
                    'MetricName': metric_name,
                    'Dimensions': [
                        {
                            'Name': 'Environment',
                            'Value': self.environment
                        },
                        {
                            'Name': 'Process',
                            'Value': self.process_name
                        },
                    ],
                    'Unit': units,
                    'Value': value
                },
            ],
            Namespace = self.metrics_namespace
        )