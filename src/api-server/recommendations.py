import logging
import math
from favorite import Favorite
from photorecommendation import PhotoRecommendation

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
    def get_recommendations(my_user_id, favorites_list, num_photo_results):

        logging.debug("Trying to calculate recommendations for user %s with a favorites list of %d items" % (my_user_id, len(favorites_list)))

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

        logging.debug("Found neighbors: %s" % ", ".join(my_neighbors.keys()))

        logging.debug("Found my favorite photo IDs: %s" % ", ".join(my_favorite_photo_ids))

        # We need to go through the list twice because it can be in any order, so we might not
        # have a neighbor object set up for a photo by the time we encounter it

        for photo in favorites_list:

            if photo.get_favorited_by() in my_neighbors.keys():
                my_neighbors[photo.get_favorited_by()]['favorite_photo_ids'].add(photo.get_image_id())
                all_neighbor_favorite_photos[photo.get_image_id()] = {
                    'score': 0,
                    'photo': photo,
                }

        # Now we can get the score for each neighbor, because we can calculate the total number of favorites
        # that they have, and the number of favorites in common with us

        for neighbor_id in my_neighbors:
            my_neighbors[neighbor_id]['total_favorites']    = len(my_neighbors[neighbor_id]['favorite_photo_ids'])
            my_neighbors[neighbor_id]['common_favorites']   = len(my_neighbors[neighbor_id]['favorite_photo_ids'] & my_favorite_photo_ids)
            my_neighbors[neighbor_id]['score']              = Recommendations._get_neighbor_score(my_neighbors[neighbor_id]['total_favorites'], my_neighbors[neighbor_id]['common_favorites'])
    
            logging.debug("Neighbor %s has %d total favorites and %d in common with me for a score of %f" % (neighbor_id, my_neighbors[neighbor_id]['total_favorites'], my_neighbors[neighbor_id]['common_favorites'], my_neighbors[neighbor_id]['score']))

        # And last we can go through all of our neighbors' favorites and score them
        # The score of a photo is the sum of the scores of all the neighbors who favorited it.
        # Taken from https://www.flickr.com/groups/709526@N23/discuss/72157604460161681/72157604455830572

        for photo in all_neighbor_favorite_photos:
            score = 0
            if photo not in my_favorite_photo_ids: # Don't recommend photos to me that I already like
                for neighbor_id in my_neighbors:
                    if photo in my_neighbors[neighbor_id]['favorite_photo_ids']:
                        score += my_neighbors[neighbor_id]['score']
            all_neighbor_favorite_photos[photo]['score'] = score

        # OPTIMIZATION: Note that this creates a copy of the list rather than sorting in place, and the list can be quite large

        sorted_neighbor_favorite_photo_ids = sorted(all_neighbor_favorite_photos.items(), key=lambda x: x[1]['score'], reverse=True)

        # The result is a list of tuples where the first element is the photo ID, and the second element is a dictionary of score and photo object

        return map(lambda photo: PhotoRecommendation(image_owner=photo[1]['photo'].get_image_owner(), image_id=photo[1]['photo'].get_image_id(), image_url=photo[1]['photo'].get_image_url(), score=photo[1]['score']), 
            sorted_neighbor_favorite_photo_ids[0:num_photo_results])
