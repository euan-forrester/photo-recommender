import jsonpickle

class PullerQueueItem:

    '''
    An item placed onto or read from the puller queue. It represents a user
    '''

    def __init__(self, user_id, request_favorites, request_contacts, request_neighbor_list):
        self.user_id                = user_id
        self.request_favorites      = request_favorites # Should the puller get the user's favorites?
        self.request_contacts       = request_contacts  # Should the puller get the user's contacts?
        self.request_neighbor_list  = request_neighbor_list # Should the puller return the user's neighbors?
   
    def get_user_id(self):
        return self.user_id

    def get_request_favorites(self):
        return self.request_favorites

    def get_request_contacts(self):
        return self.request_contacts

    def get_request_neighbor_list(self):
        return self.request_neighbor_list

    def to_json(self):
        return jsonpickle.encode(self)

    @staticmethod
    def from_json(json):
        return jsonpickle.decode(json)
        