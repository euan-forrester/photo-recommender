class UserRecommendation():

    '''
    A recommendation for a particular user
    '''

    def __init__(self, user_id, num_favorites_in_total, num_favorites_in_common, score):
        self.user_id                    = user_id
        self.num_favorites_in_total     = num_favorites_in_total
        self.num_favorites_in_common    = num_favorites_in_common
        self.score                      = score  

    def get_user_id(self):
        return self.user_id

    def get_num_favorites_in_total(self):
        return self.num_favorites_in_total

    def get_num_favorites_in_common(self):
        return self.num_favorites_in_common

    def get_score(self):
        return self.score
        
    def get_output(self):
        # Don't want to leak the scores or other info to the front end
        # Might consider getting and storing more info about individual users at some point in the future,
        # at which time that could be returned here. For now, we'll just get that info from the frontend
        return {
            'user_id': self.user_id
        }