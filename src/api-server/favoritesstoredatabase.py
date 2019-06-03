import mysql.connector.pooling
import logging
from photorecommendation import PhotoRecommendation
from favoritesstoreexception import FavoritesStoreException

class FavoritesStoreDatabase:

    '''
    This class interfaces with a MySQL database to retrieve a list of my favorites and the favorites of my neighbors
    '''

    def __init__(self, database_username, database_password, database_host, database_port, database_name, connection_pool_size, fetch_batch_size):
        
        # Note that we're using a buffered cursor, meaning that it downloads all results from the database before returning the
        # first result, rather than retrieving results as it needs them.
        #
        # I found that using an unbuffered cursor with mysql.connector had a bug where the same result would be returned infinitely
        # at the end of a result set when using fetchmany(), at least with a lot of results being returned.
        #
        # So I tried switching to the PyMySql library instead, which did not have this bug. However, the support for connection
        # pooling in PyMySql is pretty poor, so it doesn't seem like a good production library to use.
        #
        # But now we're just returning small result sets, so it seems okay to just use a buffered cursor and switch back to the 
        # mysql.connector lib instead.

        # See here for a full list of possible args in this struct: https://dev.mysql.com/doc/connector-python/en/connector-python-connectargs.html
        dbconfig = {
            "database": database_name,
            "user":     database_username,
            "password": database_password,
            "host":     database_host,
            "port":     database_port
        }

        self.cnxpool            = mysql.connector.pooling.MySQLConnectionPool(pool_name = "favorites",
                                                                              pool_size = connection_pool_size,
                                                                              **dbconfig)

        self.fetch_batch_size   = fetch_batch_size

    def get_photo_recommendations(self, user_id, num_photos):

        cnx = self.cnxpool.get_connection()

        cursor = cnx.cursor() 

        try:
            # See SQL queries.md for an explanation of the various portions of this query
            #
            # Note that although this query is brutal, brittle, and difficult to understand, it results in about a 10x speedup (0.4s vs 4s)
            # versus just getting all of the favorites data from the database (could be 10s or 100s of thousands of records)
            # then doing the scoring and sorting in the API server

            # OPTIMIZATION: Is it possible to pre-compile this statement? 

            # Took the scoring formula from https://www.flickr.com/groups/709526@N23/discuss/72157604460161681/72157604455830572

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
            cnx.close()

    def _iter_row(self, cursor):
        while True:
            rows = cursor.fetchmany(self.fetch_batch_size)
            if not rows:
                break
            for row in rows:
                yield row

    def shutdown(self):
        # Nothing to do: don't need to close a connection pool
        return
