import jsonpickle

class IngesterResponseQueueItem:

    '''
    An item placed onto or read from the ingester response queue. It represents a batch of items ingested into the database
    '''

    def __init__(self, user_id, initial_requesting_user_id, contained_num_favorites, contained_num_contacts):
        self.user_id                    = user_id
        self.initial_requesting_user_id = initial_requesting_user_id
        self.contained_num_favorites    = contained_num_favorites
        self.contained_num_contacts     = contained_num_contacts
   
    def get_user_id(self):
        return self.user_id

    def get_initial_requesting_user_id(self):
        return self.initial_requesting_user_id

    def get_contained_num_favorites(self):
        return self.contained_num_favorites

    def get_contained_num_contacts(self):
        return self.contained_num_contacts

    def to_json(self):
        return jsonpickle.encode(self)

    @staticmethod
    def from_json(json):
        return jsonpickle.decode(json)
        