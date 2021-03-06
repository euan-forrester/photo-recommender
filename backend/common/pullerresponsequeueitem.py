import jsonpickle

class PullerResponseQueueItem:

    # The max size of an SQS message is 256kB, and a user ID takes about 16 bytes to store (12 digits, plus quotes, comma, and space).
    # If we start to exceed this threshold, we should switch to storing the neighbor list in S3 
    # (if it's bigger than a certain size, to prevent hitting S3 for super small lists?) and just having a link stored in this message
    MAX_NUM_NEIGHBORS = 16000 

    '''
    An item placed onto or read from the puller response queue. It represents a user
    '''

    def __init__(self, user_id, initial_requesting_user_id, favorites_requested, contacts_requested, neighbor_list_requested, neighbor_list):
        self.user_id                    = user_id
        self.initial_requesting_user_id = initial_requesting_user_id
        self.favorites_requested        = favorites_requested
        self.contacts_requested         = contacts_requested
        self.neighbor_list_requested    = neighbor_list_requested
        self.max_neighbors_exceeded     = len(neighbor_list) > PullerResponseQueueItem.MAX_NUM_NEIGHBORS
        self.neighbor_list              = neighbor_list[:PullerResponseQueueItem.MAX_NUM_NEIGHBORS]
   
    def get_user_id(self):
        return self.user_id

    def get_initial_requesting_user_id(self):
        return self.initial_requesting_user_id

    def get_favorites_requested(self):
        return self.favorites_requested

    def get_contacts_requested(self):
        return self.contacts_requested

    def get_neighbor_list_requested(self):
        return self.neighbor_list_requested

    def get_neighbor_list(self):
        return self.neighbor_list

    def get_max_neighbors_exceeded(self):
        return self.max_neighbors_exceeded

    def to_json(self):
        return jsonpickle.encode(self)

    @staticmethod
    def from_json(json):
        return jsonpickle.decode(json)
        