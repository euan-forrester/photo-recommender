class ContactItem:

    def __init__(self, follower_id, followee_id):
        self.follower_id = follower_id
        self.followee_id = followee_id

    def get_follower_id(self):
        return self.follower_id

    def get_followee_id(self):
        return self.followee_id