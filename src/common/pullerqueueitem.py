import jsonpickle

class PullerQueueItem:

    '''
    An item placed onto or read from the puller queue. It represents a user
    '''

    def __init__(self, user_id, is_registered_user):
        self.user_id            = user_id
        self.is_registered_user = is_registered_user
   
    def get_user_id(self):
        return self.user_id

    def get_is_registered_user(self):
        return self.is_registered_user

    def to_json(self):
        return jsonpickle.encode(self)

    @staticmethod
    def from_json(json):
        return jsonpickle.decode(json)
        