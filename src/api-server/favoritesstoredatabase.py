import pymysql
import pymysql.cursors
import logging
from favorite import Favorite
from photorecommendation import PhotoRecommendation
from favoritesstoreexception import FavoritesStoreException

class FavoritesStoreDatabase:

    '''
    This class interfaces with a MySQL database to retrieve a list of my favorites and the favorites of my neighbors
    '''

    def __init__(self, database_username, database_password, database_host, database_port, database_name, fetch_batch_size):
        
        # Note that pymysql.cursors.SSCursor is an unbuffered cursor, meaning that it only retrieves rows as it needs them, rather than all at once.
        # We're retrieving a large dataset here, so having only a few in memory at once is preferred. Although we end up creating an object for
        # every row anyway, and keeping them all in memory at once, so it's not a huge deal.
        #
        # I tried using mysql.connector, but only its buffered cursor worked as expected: using an unbuffered cursor resulted in having
        # a single row being returned over and over by fetchmany() after all of the correct results had been returned. So it would be difficult to
        # determine whether we were actually at the end of our resultset or not. This appears to be a bug in that connector lib, because a buffered 
        # cursor worked as expected, and the same code worked fine for an unbuffered (and buffered) cursor with the pymysql package.
        #
        # Solutions tried: upgrading python, upgrading the mysql-connector-python package, downgrading the database from MySQL 8.0 to 5.7
        # Couldn't find anything with various google searches.
        # Maybe later this bug will be fixed and we can switch back to the mysql.connector package?

        self.cnx                = pymysql.connect(
                                    user=database_username, 
                                    password=database_password, 
                                    host=database_host, 
                                    port=database_port, 
                                    db=database_name, 
                                    cursorclass=pymysql.cursors.SSCursor) # Unbuffered cursor: https://pymysql.readthedocs.io/en/latest/modules/cursors.html
        
        self.fetch_batch_size   = fetch_batch_size

    def get_photo_recommendations(self, user_id, num_photos):

        cursor = self.cnx.cursor() 

        logging.debug(f"Trying to get recommendations for user '{user_id}'")

        try:
            # See SQL queries.md for an explanation of the various portions of this query
            #
            # Note that although this query is brutal, brittle, and difficult to understand, it results in about a 10x speedup (0.4s vs 4s)
            # versus just getting all of the favorites data from the database (could be 10s or 100s of thousands of records)
            # then doing the scoring and sorting in the API server

            cursor.execute("""
                select possible_photos.image_id, possible_photos.image_owner, possible_photos.image_url, sum(neighbor_scores.score) as 'total_score' from
                        (select image_id, image_owner, image_url, favorited_by from favorites 
                            where 
                                favorited_by in (select distinct image_owner from favorites where favorited_by=%s) 
                            and
                                image_id not in (select image_id from favorites where favorited_by=%s)) as possible_photos
                    join
                        (select 
                            total_favorites.neighbor_user_id as 'neighbor_user_id', 
                            total_favorites.num_favorites as 'num_favorites', 
                            ifnull(common_favorites.num_favorites_in_common, 0) as 'num_favorites_in_common', 
                            150 * sqrt(ifnull(common_favorites.num_favorites_in_common, 0) / (total_favorites.num_favorites + 250)) as 'score' 
                        from
                            (select favorited_by as 'neighbor_user_id', count(image_id) as 'num_favorites' from favorites where favorited_by in 
                                (select distinct image_owner from favorites where favorited_by=%s) 
                                group by favorited_by) as total_favorites
                        left join 
                            (select neighbor_favorites.favorited_by as 'neighbor_user_id', count(neighbor_favorites.image_id) as 'num_favorites_in_common' from
                                favorites as my_favorites join favorites as neighbor_favorites
                                on my_favorites.image_id = neighbor_favorites.image_id
                                where my_favorites.favorited_by=%s and neighbor_favorites.favorited_by in (select distinct image_owner from favorites where favorited_by=%s) 
                                group by neighbor_favorites.favorited_by) as common_favorites
                        on 
                            total_favorites.neighbor_user_id = common_favorites.neighbor_user_id) as neighbor_scores
                    on possible_photos.favorited_by = neighbor_scores.neighbor_user_id
                    group by possible_photos.image_id
                    order by total_score desc
                    limit 0,%s; 
            """, (user_id, user_id, user_id, user_id, user_id, num_photos))
     
            recommendations = []

            for row in self._iter_row(cursor):
                recommendations.append(PhotoRecommendation(image_id=row[0], image_owner=row[1], image_url=row[2], score=row[3]))

            return recommendations

        except Exception as e:
            raise FavoritesStoreException from e

        finally:
            cursor.close()

    def get_my_favorites_and_neighbors_favorites(self, user_id):

        cursor = self.cnx.cursor() 

        logging.debug("Trying to get rows for user '%s'" % user_id)

        try:
            cursor.execute("""
                select 
                    id, image_id, image_owner, image_url, favorited_by 
                from 
                    favorites 
                where 
                    favorited_by=%s 
                or 
                    favorited_by in (select distinct image_owner from favorites where favorited_by=%s);
            """, (user_id, user_id))
     
            favorites = []

            for row in self._iter_row(cursor):
                logging.debug("Got a row!", row)
                favorites.append(Favorite(id=row[0], image_id=row[1], image_owner=row[2], image_url=row[3], favorited_by=row[4]))

            return favorites

        except Exception as e:
            raise FavoritesStoreException from e

        finally:
            cursor.close()

 
    def _iter_row(self, cursor):
        while True:
            rows = cursor.fetchmany(self.fetch_batch_size)
            logging.debug("Just fetched %d rows" % len(rows))
            if not rows:
                break
            for row in rows:
                yield row

    def shutdown(self):
        self.cnx.close()