import jsonpickle

class IngesterQueueBatchItem:

    '''
    An item placed onto or read from the ingester queue. It represents a set of favorite (or equivalent) photos
    '''

    def __init__(self, item_list):
        self.item_list = item_list
   
    def get_item_list(self):
        return self.item_list

    def to_json(self):
        return jsonpickle.encode(self)

    @staticmethod
    def from_json(json):
        return jsonpickle.decode(json)
        