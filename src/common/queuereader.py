import boto3
import logging

class SQSMessage:

    '''
    Represents a single message read from an SQS queue
    '''

    def __init__(self, message_body, message_receipt_handle):
        self.message_body           = message_body
        self.message_receipt_handle = message_receipt_handle

    def get_message_body(self):
        return self.message_body

    def _get_message_receipt_handle(self):
        return self.message_receipt_handle

class QueueReaderException(Exception):
    '''
    Thrown when we have an error reading from a queue. 

    In general we do not want to catch this exception so that the process dies and the queue can be re-read later.
    '''
    pass

class SQSQueueReader:

    '''
    Wraps an SQS queue and allows for receiving messages from that queue.

    It has a maximum number of messages to read, even if there's more left in the queue,
    so that the calling program will eventually terminate even when reading from a very long queue. 
    Thus avoiding the hard-to-reproduce problems that tend to crop up in long-running processes.
    
    We have to take in this max value here because otherwise there may be messages which are read
    from the queue but not processed because they exceed the maximum, and then that would
    count against their number of redrives and possibly get them sent to the dead-letter queue prematurely.
    '''

    def __init__(self, queue_url, batch_size, max_messages_to_read, metrics_helper):
        self.sqs                    = boto3.client('sqs') # Region is read from the AWS_DEFAULT_REGION env var. Seems necessary even though it's superfluous because it's in the queue URL
        self.queue_url              = queue_url
        self.batch_size             = batch_size
        self.max_messages_to_read   = max_messages_to_read
        self.current_batch_read     = [] # Remaining portion of the last batch of messages read from the queue
        self.total_messages_read    = 0  # Total number of messages that we've read from the queue
        self.current_batch_finished = [] # The current batch of messages that have been successfully processed'
        self.metrics_helper         = metrics_helper

    def __iter__(self):
        return self

    def __next__(self):

        if (len(self.current_batch_read) == 0) and (self.total_messages_read < self.max_messages_to_read):

            response = self.sqs.receive_message(
                QueueUrl=self.queue_url, 
                MaxNumberOfMessages=min(self.batch_size, self.max_messages_to_read - self.total_messages_read)
                # Other possible parameters, such as visibility timeout and long polling are set on the queue itself from terraform
            )

            if 'Messages' in response:
                self.current_batch_read  = response['Messages']
                self.total_messages_read += len(self.current_batch_read)

            else:
                logging.warn(f"Failed to get messages from queue {self.queue_url}")
                SQSQueueReader._log_sender_fault_and_reason(response)
                self.metrics_helper.increment_count("QueueReaderError") 
                raise QueueReaderException(f"Failed to get messages from queue {self.queue_url}")             

        if len(self.current_batch_read) == 0:
            raise StopIteration()

        raw_message = self.current_batch_read.pop(0)

        message = SQSMessage(raw_message['Body'], raw_message['ReceiptHandle'])

        return message

    def finished_with_message(self, message):

        self.current_batch_finished.append(message)

        if len(self.current_batch_finished) >= self.batch_size:
            self._purge_finished_messages()

    def get_total_number_of_messages_available(self):

        response = self.sqs.get_queue_attributes(
            QueueUrl=self.queue_url,
            AttributeNames=[
                'ApproximateNumberOfMessages',
                'ApproximateNumberOfMessagesNotVisible',
                'ApproximateNumberOfMessagesDelayed'
            ]
        )

        total_messages = 0

        if 'Attributes' in response:
            total_messages += int(response['Attributes']['ApproximateNumberOfMessages'])
            total_messages += int(response['Attributes']['ApproximateNumberOfMessagesNotVisible'])
            total_messages += int(response['Attributes']['ApproximateNumberOfMessagesDelayed'])

        else:
            logging.warn(f"Failed to get attributes from queue {self.queue_url}")
            SQSQueueReader._log_sender_fault_and_reason(response)
            self.metrics_helper.increment_count("QueueReaderError")
            raise QueueReaderException(f"Failed to get attributes from queue {self.queue_url}") 

        return total_messages

    def shutdown(self):
        self._purge_finished_messages()

    def _purge_finished_messages(self):

        if len(self.current_batch_finished) == 0:
            return

        delete_message_entries = []

        for finished_message in self.current_batch_finished:

            message = {
                'Id': str(len(delete_message_entries)),
                'ReceiptHandle': finished_message._get_message_receipt_handle()
            }

            delete_message_entries.append(message)

        self.current_batch_finished = []

        response = self.sqs.delete_message_batch(
            QueueUrl=self.queue_url,
            Entries=delete_message_entries
        )

        if 'Failed' in response:

            num_failed_messages = len(response['Failed'])

            if num_failed_messages > 0:
                logging.warn(f"Unable to delete {num_failed_messages} messages from queue {self.queue_url}")
                SQSQueueReader._log_sender_fault_and_reason(response)
                self.metrics_helper.increment_count("QueueReaderError")
                raise QueueReaderException(f"Unable to delete {num_failed_messages} messages from queue {self.queue_url}")

    @staticmethod
    def _log_sender_fault_and_reason(response):
        logging.warn(f"Last SenderFault: {response['Failed'][num_failed_messages - 1]['SenderFault']} Last reason: {response['Failed'][num_failed_messages - 1]['Message']}")

