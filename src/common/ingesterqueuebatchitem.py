import jsonpickle

class IngesterQueueBatchItem:

    '''
    An item placed onto or read from the ingester queue. It represents a set of favorite (or equivalent) photos and/or a set of contacts
    '''

    # The max size of an SQS message is 256kB, and 1000 photos takes about 218kB
    # If we start to exceed this threshold, we should switch to breaking up the batch message into multiple messages or storing the photo list in S3 
    # (if it's bigger than a certain size, to prevent hitting S3 for super small lists?) and just having a link stored in this message
    MAX_FAVORITES = 1000 

    MAX_CONTACTS = 15000 # A contact is just an ID string, about 17 bytes long

    def __init__(self, favorites_list, contacts_list):
        self.max_favorites_exceeded = len(favorites_list) > IngesterQueueBatchItem.MAX_FAVORITES
        self.favorites_list         = favorites_list[:IngesterQueueBatchItem.MAX_FAVORITES]
    
        self.max_contacts_exceeded  = len(contacts_list) > IngesterQueueBatchItem.MAX_CONTACTS
        self.contacts_list          = contacts_list[:IngesterQueueBatchItem.MAX_CONTACTS]

    def get_favorites_list(self):
        return self.favorites_list

    def get_max_favorites_exceeded(self):
        return self.max_favorites_exceeded

    def get_contacts_list(self):
        return self.contacts_list

    def get_max_contacts_exceeded(self):
        return self.max_contacts_exceeded

    def to_json(self):
        return jsonpickle.encode(self)

    @staticmethod
    def from_json(json):
        return jsonpickle.decode(json)
        