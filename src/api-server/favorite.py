class Favorite:

    '''
    A favorite (or equivalent) photo read from the data store
    '''

    def __init__(self, id, image_id, image_url, image_owner, favorited_by):
        self.id             = id
        self.image_id       = image_id
        self.image_url      = image_url
        self.image_owner    = image_owner
        self.favorited_by   = favorited_by  
   
    def get_id(self):
        return self.id

    def get_image_id(self):
        return self.image_id

    def get_image_url(self):
        return self.image_url

    def get_image_owner(self):
        return self.image_owner

    def get_favorited_by(self):
        return self.favorited_by
        