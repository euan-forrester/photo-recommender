import logging
import math
from favorite import Favorite

class Recommendations:

    '''
    This class contains the business logic of figuring out a set of recommendations for a user based
    on their favorites and the favorites of their neighbors
    '''

    @staticmethod
    def _get_neighbor_score(total_favorites, common_favorites):
        # Took this formula from https://www.flickr.com/groups/709526@N23/discuss/72157604460161681/72157604455830572
        return 150 * math.sqrt(common_favorites / (total_favorites + 250))

    @staticmethod
    def get_recommendations(my_user_id, favorites_list):

        logging.info("Trying to calculate recommendations for user %s with a favorites list of %d items" % (my_user_id, len(favorites_list)))

        # favorites_list contains a jumble of my own favorites as well as the favorites of my neighbors.
        # So the first thing to do is to separate them from each other

        my_favorite_photos = []
        my_favorite_photo_ids = set()
        my_neighbors = {}
        all_neighbor_favorite_photos = {}

        for photo in favorites_list:

            if photo.get_favorited_by() == my_user_id:
                
                my_favorite_photos.append(photo)
                my_favorite_photo_ids.add(photo.get_image_id())

                if photo.get_image_owner() not in my_neighbors:
                    
                    my_neighbors[photo.get_image_owner()] = { 
                        'user_id'               : photo.get_image_owner(), 
                        'favorite_photo_ids'    : set(),
                        'total_favorites'       : 0,
                        'common_favorites'      : 0,
                        'score'                 : 0
                    }

        logging.info("Found neighbors: %s" % ", ".join(my_neighbors.keys()))

        logging.info("Found my favorite photo IDs: %s" % ", ".join(my_favorite_photo_ids))

        # We need to go through the list twice because it can be in any order, so we might not
        # have a neighbor object set up for a photo by the time we encounter it

        for photo in favorites_list:

            if photo.get_favorited_by() in my_neighbors.keys():
                my_neighbors[photo.get_favorited_by()]['favorite_photo_ids'].add(photo.get_image_id())
                all_neighbor_favorite_photos[photo.get_image_id()] = {
                    'score': 0,
                    'photo': photo,
                }

                if photo.get_image_id() in my_favorite_photo_ids:
                    logging.info("Ah ha! Found one!")

            else:
                if photo.get_favorited_by() != my_user_id:
                    logging.info("WTF -- where did this photo come from?")

        # Now we can get the score for each neighbor, because we can calculate the total number of favorites
        # that they have, and the number of favorites in common with us

        for neighbor_id in my_neighbors:
            my_neighbors[neighbor_id]['total_favorites']    = len(my_neighbors[neighbor_id]['favorite_photo_ids'])
            my_neighbors[neighbor_id]['common_favorites']   = len(my_neighbors[neighbor_id]['favorite_photo_ids'] & my_favorite_photo_ids)
            my_neighbors[neighbor_id]['score']              = Recommendations._get_neighbor_score(my_neighbors[neighbor_id]['total_favorites'], my_neighbors[neighbor_id]['common_favorites'])
    
            logging.info("Neighbor %s has %d total favorites and %d in common with me for a score of %f" % (neighbor_id, my_neighbors[neighbor_id]['total_favorites'], my_neighbors[neighbor_id]['common_favorites'], my_neighbors[neighbor_id]['score']))
