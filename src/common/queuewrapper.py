import boto3
import logging

class SQSQueue:

    '''
    Wraps an SQS queue
    '''

    def __init__(self, queue_url, batch_size):
        self.sqs        = boto3.client('sqs') # Region is read from the AWS_DEFAULT_REGION env var. Seems necessary even though it's superfluous because it's in the queue URL
        self.queue_url  = queue_url
        self.batch_size = batch_size

    def send_messages(self, objects, to_string):
        current_batch = []

        for obj in objects:

            message = {
                'Id': str(len(current_batch)),
                'MessageBody': to_string(objects[obj])
            }

            current_batch.append(message)

            if len(current_batch) >= self.batch_size:

                self._send_batch(current_batch)

                current_batch = []

        self._send_batch(current_batch) # Send any remaining items that didn't make a full batch


    def _send_batch(self, current_batch):

        response = self.sqs.send_message_batch(
            QueueUrl=self.queue_url,
            Entries=current_batch
        )

        if len(current_batch) == len(response['Successful']):
            logging.info("All %d messages in batch sent successfully" % (len(current_batch)))
        else:
            logging.warn("%d messages in batch of %d were not sent successfully" % (len(response['Failed']), len(current_batch)))

            for failed_message in response['Failed']:
                logging.warn("Failed message: ", failed_message)

            # TODO: Increment a metric that we can alert on