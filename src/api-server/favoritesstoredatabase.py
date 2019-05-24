import mysql.connector
import logging
from favorite import Favorite
from favoritesstoreexception import FavoritesStoreException

class FavoritesStoreDatabase:

    def __init__(self, database_username, database_password, database_host, database_port, database_name, fetch_batch_size):
        self.cnx                = mysql.connector.connect(user=database_username, password=database_password, host=database_host, port=database_port, database=database_name)
        self.fetch_batch_size   = fetch_batch_size

    def get_my_favorites_and_neighbors_favorites(self, user_id):

        # Using a nonbuffered cursor here results in the same row being returned over and over at the end of the results. 
        # Using a buffered cursor behaves as expected. Is this a bug in mysql or the driver?
        # The problem is that a buffered cursor retrieves all of the results at once, and our result set can be large.
        #
        # Solutions tried: upgrading python, upgrading the mysql-connector-python package, downgrading the database from MySQL 8.0 to 5.7
        # Couldn't find anything with various google searches.
        # Consider trying a different package to connect to MySQL
        cursor = self.cnx.cursor(buffered=False) 

        print("Trying to get rows for user '%s'" % user_id)

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
                favorites.append(Favorite(id=row[0], image_id=row[1], image_url=row[2], image_owner=row[3], favorited_by=row[4]))

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