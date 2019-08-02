import jsonpickle

class IngesterQueueBatchItem:

    '''
    An item placed onto or read from the ingester queue. It represents a set of favorite (or equivalent) photos
    '''

    # The max size of an SQS message is 256kB, and 1000 photos takes about 218kB
    # If we start to exceed this threshold, we should switch to breaking up the batch message into multiple messages or storing the photo list in S3 
    # (if it's bigger than a certain size, to prevent hitting S3 for super small lists?) and just having a link stored in this message
    MAX_NUM_ITEMS = 1000 

    def __init__(self, item_list):
        self.max_items_exceeded = len(item_list) > IngesterQueueBatchItem.MAX_NUM_ITEMS
        self.item_list          = item_list[:IngesterQueueBatchItem.MAX_NUM_ITEMS]
    
    def get_item_list(self):
        return self.item_list

    def get_max_items_exceeded(self):
        return self.max_items_exceeded

    def to_json(self):
        return jsonpickle.encode(self)

    @staticmethod
    def from_json(json):
        return jsonpickle.decode(json)
        