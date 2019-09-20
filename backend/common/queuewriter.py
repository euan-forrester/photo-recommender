import boto3
import logging

class QueueWriterException(Exception):
    '''
    Thrown when we have an error writing to a queue. 

    In general we do not want to catch this exception so that the process dies and the messages that were read which caused these
    messages to be written are redriven.
    '''
    pass

class SQSQueueWriter:

    '''
    Wraps an SQS queue and allows for sending messages to that queue
    '''

    def __init__(self, queue_url, batch_size, metrics_helper):
        self.sqs        = boto3.client('sqs') # Region is read from the AWS_DEFAULT_REGION env var. Seems necessary even though it's superfluous because it's in the queue URL
        self.queue_url  = queue_url
        self.batch_size = batch_size

    def send_messages(self, objects, to_string):
        current_batch = []

        for obj in objects:

            message = {
                'Id': str(len(current_batch)),
                'MessageBody': to_string(obj)
            }

            logging.info(f"Sending message with a body containing {len(message['MessageBody']) / 1024} kB")

            current_batch.append(message)

            if len(current_batch) >= self.batch_size:

                self._send_batch(current_batch)

                current_batch = []

        self._send_batch(current_batch) # Send any remaining items that didn't make a full batch


    def _send_batch(self, current_batch):

        if len(current_batch) > 0:

            response = self.sqs.send_message_batch(
                QueueUrl=self.queue_url,
                Entries=current_batch
            )

            if len(current_batch) == len(response['Successful']):
                logging.info(f"All {len(current_batch)} messages in batch sent successfully")
            else:
                logging.warn(f"{len(response['Failed'])} messages in batch of {len(current_batch)} were not sent successfully")

                for failed_message in response['Failed']:
                    logging.warn(f"Failed message: {failed_message}")

                metrics_helper.increment_count("QueueWriterError")

                raise QueueWriterException(f"Failed to send {len(response['Failed'])} of {len(current_batch)} messages to queue {self.queue_url}")
