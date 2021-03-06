import jsonpickle

class PullerQueueItem:

    '''
    An item placed onto or read from the puller queue. It represents a user
    '''

    def __init__(self, user_id, initial_requesting_user_id, request_favorites, request_contacts, request_neighbor_list):
   
        # As an optimization, we're going to make the assumption that one message to the puller results in
        # one message to the ingester. Otherwise we have to have the puller report how many messages it
        # generated, and either send that directly to the API server (slowing down the puller), or added
        # to its response message. But then that response message, and the ingester message and its response,
        # may not be processed in the expected order, resulting in false positives when detecting whether
        # all ingester messages have been processed.

        if request_favorites and request_contacts:
            raise RuntimeError("Can only request one thing at a time from the puller")

        self.user_id                    = user_id
        self.initial_requesting_user_id = initial_requesting_user_id
        self.request_favorites          = request_favorites # Should the puller get the user's favorites?
        self.request_contacts           = request_contacts  # Should the puller get the user's contacts?
        self.request_neighbor_list      = request_neighbor_list # Should the puller return the user's neighbors?
   
    def get_user_id(self):
        return self.user_id

    def get_initial_requesting_user_id(self):
        return self.initial_requesting_user_id

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
        
    @staticmethod
    def get_messages_to_request_all_data_for_user(user_id):
        # We can't necessarily fit a user's favorites + their contacts in a single message to the ingester queue, so split them up. 
        # A user's favorites barely fit as is, and also that'll let us request the two datasets concurrently in 2 processes, 
        # rather than one then the other in a single process

        puller_requests_for_user = []

        puller_requests_for_user.append(PullerQueueItem(user_id=user_id, initial_requesting_user_id=user_id, request_favorites=True, request_contacts=False, request_neighbor_list=True))
        puller_requests_for_user.append(PullerQueueItem(user_id=user_id, initial_requesting_user_id=user_id, request_favorites=False, request_contacts=True, request_neighbor_list=False))

        return puller_requests_for_user