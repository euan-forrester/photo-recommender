import jsonpickle

class IngesterQueueItem:

    '''
    An item placed onto or read from the ingester queue. It represents a favorite (or equivalent) photo
    '''

    def __init__(self, image_id, image_url, owner, favorited_by):
        self.image_id       = image_id
        self.image_url      = image_url
        self.owner          = owner
        self.favorited_by   = favorited_by  
   
    def get_image_id(self):
        return self.image_id

    def get_image_url(self):
        return self.image_url

    def get_owner(self):
        return self.owner

    def get_favorited_by(self):
        return self.favorited_by

    def to_json(self):
        return jsonpickle.encode(self)

    @staticmethod
    def from_json(json):
        return jsonpickle.decode(from_json)
        