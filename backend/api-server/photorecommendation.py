class PhotoRecommendation():

    '''
    A recommendation for a particular photo
    '''

    def __init__(self, image_id, image_url, image_owner, score):
        self.image_id       = image_id
        self.image_url      = image_url
        self.image_owner    = image_owner
        self.score          = score  

    def get_image_id(self):
        return self.image_id

    def get_image_url(self):
        return self.image_url

    def get_image_owner(self):
        return self.image_owner

    def get_score(self):
        return self.score
        
    def get_output(self):
        # Don't want to leak the scores to the front end
        return {
            'image_id': self.image_id,
            'image_url': self.image_url,
            'image_owner': self.image_owner
        }