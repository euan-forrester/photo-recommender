class IngesterQueueItem:

    '''
    An item placed onto or read from a batch message on the ingester queue. It represents a favorite (or equivalent) photo
    '''

    def __init__(self, image_id, image_url, image_owner, favorited_by):
        self.image_id       = image_id
        self.image_url      = image_url
        self.image_owner    = image_owner
        self.favorited_by   = favorited_by  
   
    def get_image_id(self):
        return self.image_id

    def get_image_url(self):
        return self.image_url

    def get_image_owner(self):
        return self.image_owner

    def get_favorited_by(self):
        return self.favorited_by
