import pymysql
import pymysql.cursors
import logging
from favorite import Favorite
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