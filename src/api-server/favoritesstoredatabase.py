import mysql.connector.pooling
import logging
from photorecommendation import PhotoRecommendation
from userrecommendation import UserRecommendation
from favoritesstoreexception import FavoritesStoreException
from favoritesstoreexception import FavoritesStoreUserNotFoundException
from favoritesstoreexception import FavoritesStoreDuplicateUserException
from mysql.connector import errorcode
from mysql.connector import errors

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

    def create_user(self, user_id):

        cnx = self.cnxpool.get_connection()

        cursor = cnx.cursor() 

        try:
            cursor.execute("""
                INSERT INTO
                    registered_users 
                SET user_id=%s;
            """, (user_id,))

            cnx.commit()

        except errors.IntegrityError as e:

            cnx.rollback()
            
            if e.errno == errorcode.ER_DUP_ENTRY:
                # We have a UNIQUE constraint on the user_id column, so we can't insert a duplicate
                raise FavoritesStoreDuplicateUserException from e
            else:
                raise FavoritesStoreException from e

        except Exception as e:
            cnx.rollback()
            raise FavoritesStoreException from e

        finally:
            cursor.close()
            cnx.close()

    def delete_user(self, user_id):

        cnx = self.cnxpool.get_connection()

        cursor = cnx.cursor() 

        rows_deleted = 0

        try:
            cursor.execute("""
                DELETE FROM 
                    registered_users 
                WHERE 
                    user_id=%s;
            """, (user_id,))

            rows_deleted = cursor.rowcount

            cnx.commit()

        except Exception as e:
            cnx.rollback()
            raise FavoritesStoreException from e

        finally:
            cursor.close()
            cnx.close()

        if rows_deleted == 0:
            raise FavoritesStoreUserNotFoundException(f"User {user_id} was not found")

    def get_user_info(self, user_id):

        cnx = self.cnxpool.get_connection()

        cursor = cnx.cursor() 

        user_info = None

        try:
            cursor.execute("""
                SELECT
                    UNIX_TIMESTAMP(created_at),
                    (all_data_last_successfully_processed_at IS NOT NULL) AS have_initially_processed_data,
                    ((all_data_last_successfully_processed_at IS NOT NULL) AND 
                        (data_last_requested_at IS NOT NULL) AND 
                        (all_data_last_successfully_processed_at < data_last_requested_at)) AS currently_processing_data
                FROM 
                    registered_users
                WHERE
                    user_id=%s
                ;
            """, (user_id,))
     
            row = self._get_first_row(cursor)
            
            if row is not None:
                user_info = {
                    'created_at':                       row[0],
                    'have_initially_processed_data':    bool(row[1]),
                    'currently_processing_data':        bool(row[2])
                }

        except Exception as e:
            raise FavoritesStoreException from e

        finally:
            cursor.close()
            cnx.close()

        if user_info is not None:
            return user_info
        else:
            raise FavoritesStoreUserNotFoundException(f"User {user_id} was not found")

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

            # Note that we exclude any photos we've already favorited from these recommendations

            cursor.execute("""
                SELECT possible_photos.image_id, possible_photos.image_owner, possible_photos.image_url, sum(neighbor_scores.score) as 'total_score' from
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

    def get_user_recommendations(self, user_id, num_users):

        cnx = self.cnxpool.get_connection()

        cursor = cnx.cursor() 

        try:
            # See SQL queries.md for an explanation of the various portions of this query
            #
            # See note above re the complexity and brittleness of this query
            #
            # Note that we exclude anyone we're currently following from these recommendations.

            # OPTIMIZATION: Is it possible to pre-compile this statement? 

            cursor.execute("""
                SELECT 
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
                    total_favorites.neighbor_user_id = common_favorites.neighbor_user_id
                where 
                    total_favorites.neighbor_user_id not in 
                        (select followee_id from followers where follower_id=%s)
                order by
                    score desc
                limit 0,%s;
            """, (user_id, user_id, user_id, user_id, num_users))
     
            recommendations = []

            for row in self._iter_row(cursor):
                recommendations.append(UserRecommendation(user_id=row[0], num_favorites_in_total=row[1], num_favorites_in_common=row[2], score=row[3]))

            return recommendations

        except Exception as e:
            raise FavoritesStoreException from e

        finally:
            cursor.close()
            cnx.close()

    def get_users_that_need_updated(self, num_seconds_between_updates):
        cnx = self.cnxpool.get_connection()

        cursor = cnx.cursor() 

        try:
            cursor.execute("""
                SELECT 
                    user_id 
                FROM 
                    registered_users 
                WHERE 
                    TIMESTAMPDIFF(SECOND, IFNULL(data_last_requested_at, TIMESTAMP('1970-01-01')), NOW()) > %s
                ;
            """, (num_seconds_between_updates,))

            users = []

            for row in self._iter_row(cursor):
                users.append(row[0])

            return users

        except Exception as e:
            raise FavoritesStoreException from e

        finally:
            cursor.close()
            cnx.close()            

    def get_users_that_are_currently_updating(self):
        cnx = self.cnxpool.get_connection()

        cursor = cnx.cursor() 

        try:
            cursor.execute("""
                SELECT 
                    user_id 
                FROM 
                    registered_users 
                WHERE 
                    IFNULL(all_data_last_successfully_processed_at, TIMESTAMP('1970-01-01')) < IFNULL(data_last_requested_at, TIMESTAMP('1970-01-01'))
                ;
            """)

            users = []

            for row in self._iter_row(cursor):
                users.append(row[0])

            return users

        except Exception as e:
            raise FavoritesStoreException from e

        finally:
            cursor.close()
            cnx.close() 

    def user_data_requested(self, user_id, num_puller_requests):
        cnx = self.cnxpool.get_connection()

        cursor = cnx.cursor() 

        try:
            cursor.execute("""
                UPDATE 
                    registered_users 
                SET 
                    data_last_requested_at = NOW(), 
                    num_puller_requests_made = %s,
                    num_puller_requests_finished = 0
                WHERE 
                    user_id=%s
                ;
            """, (num_puller_requests, user_id))

            cnx.commit()

        except Exception as e:
            cnx.rollback()
            raise FavoritesStoreException from e

        finally:
            cursor.close()
            cnx.close()         

    def more_puller_requests(self, user_id, num_puller_requests):
        cnx = self.cnxpool.get_connection()

        cursor = cnx.cursor() 

        try:
            cursor.execute("""
                UPDATE 
                    registered_users 
                SET 
                    num_puller_requests_made = num_puller_requests_made + %s
                WHERE 
                    user_id=%s
                ;
            """, (num_puller_requests, user_id))

            cnx.commit()

        except Exception as e:
            cnx.rollback()
            raise FavoritesStoreException from e

        finally:
            cursor.close()
            cnx.close()  

    def received_puller_responses(self, user_id, num_puller_responses):
        cnx = self.cnxpool.get_connection()

        cursor = cnx.cursor() 

        try:
            cursor.execute("""
                UPDATE 
                    registered_users 
                SET 
                    num_puller_requests_finished = num_puller_requests_finished + %s
                WHERE 
                    user_id=%s
                ;
            """, (num_puller_responses, user_id))

            cnx.commit()

        except Exception as e:
            cnx.rollback()
            raise FavoritesStoreException from e

        finally:
            cursor.close()
            cnx.close()  

    def all_user_data_updated(self, user_id):
        cnx = self.cnxpool.get_connection()

        cursor = cnx.cursor() 

        try:
            cursor.execute("""
                UPDATE 
                    registered_users 
                SET 
                    all_data_last_successfully_processed_at = NOW() 
                WHERE 
                    user_id=%s;
            """, (user_id,))

            cnx.commit()

        except Exception as e:
            cnx.rollback()
            raise FavoritesStoreException from e

        finally:
            cursor.close()
            cnx.close() 

    def get_time_to_update_all_data(self, user_id):

        cnx = self.cnxpool.get_connection()

        cursor = cnx.cursor() 

        try:
            cursor.execute("""
                SELECT 
                    TIMESTAMPDIFF(
                        SECOND, 
                        IFNULL(data_last_requested_at, TIMESTAMP('1970-01-01')), 
                        IFNULL(all_data_last_successfully_processed_at, TIMESTAMP('1970-01-01'))) 
                AS 
                    time_to_complete 
                FROM
                    registered_users
                WHERE 
                    user_id=%s
                ;
            """, (user_id,))
     
            row = self._get_first_row(cursor)
                
            return row[0]

        except Exception as e:
            raise FavoritesStoreException from e

        finally:
            cursor.close()
            cnx.close()

    def request_lock(self, process_id, task_id, lock_duration_seconds):

        cnx = self.cnxpool.get_connection()

        cursor = cnx.cursor() 

        lock_acquired = False

        try:
            # This is a two-step process so we need to be in a transaction

            cnx.start_transaction(isolation_level="SERIALIZABLE")

            # First, see which task has the lock for this process. Note that we put a lock on the row we return with FOR UPDATE 
            # so that no one else can update it until this transaction finishes

            cursor.execute("""
                SELECT 
                    TIMESTAMPDIFF(SECOND, NOW(), lock_expiry) as seconds_until_lock_expiry, 
                    task_id
                FROM
                    task_locks
                WHERE 
                    process_id=%s
                FOR UPDATE;
            """, (process_id,))

            row = self._get_first_row(cursor)

            seconds_until_lock_expiry = None
            task_which_has_lock = None

            if row is not None:            
                seconds_until_lock_expiry = row[0]
                task_which_has_lock = row[1]

            logging.info(f"Trying to acquire lock for process {process_id}, task {task_id}. Lock for this process is currently owned by task {task_which_has_lock}, and will expire in {seconds_until_lock_expiry} seconds")

            task_matches = (task_which_has_lock is None) or (task_which_has_lock == task_id)

            if task_matches or (seconds_until_lock_expiry < 0):
                lock_acquired = True

                # This is an upsert operation: process_id has a UNIQUE constaint, so if there's already 
                # this process in the database then just update the existing row.  

                cursor.execute("""
                    INSERT INTO
                        task_locks
                    SET
                        process_id=%s,
                        task_id=%s,
                        lock_expiry=TIMESTAMPADD(SECOND, %s, NOW())
                    ON DUPLICATE KEY UPDATE
                        task_id=%s,
                        lock_expiry=TIMESTAMPADD(SECOND, %s, NOW());
                """, (process_id, task_id, lock_duration_seconds, task_id, lock_duration_seconds))                

                rows_updated = cursor.rowcount

                # The number of rows affected by this operation is:
                #   0: the row is exactly the same as it was
                #   1: a new row was inserted
                #   2: an existing row was updated

                if (rows_updated < 0) or (rows_updated > 2):
                    raise FavoritesStoreException(f"Updated {rows_updated} when trying to acquire a lock, rather than 0, 1, or 2")

                logging.info(f"Task {task_id} was able to successfully acquire lock for process {process_id}")

            else:  
                logging.info(f"Task {task_id} was unable to acquire lock for process {process_id}. It is currently owned by task {task_which_has_lock} for the next {seconds_until_lock_expiry} seconds")

            cnx.commit()

            return lock_acquired

        except errors.InternalError as e:

            cnx.rollback()
            
            if e.errno == errorcode.ER_LOCK_DEADLOCK:
                # I don't know why deadlocks occasionally happen with this code. It seems like it's just a thing
                # that happens sometimes.
                #
                # "They are not dangerous unless they are so frequent that you cannot run certain transactions at all." 
                # "You must write your applications so that they are always prepared to re-issue a transaction 
                #  if it gets rolled back because of a deadlock."
                #
                # https://dev.mysql.com/doc/refman/8.0/en/server-error-reference.html
                # https://dev.mysql.com/doc/refman/8.0/en/innodb-deadlocks.html
                # https://dev.mysql.com/doc/refman/8.0/en/innodb-deadlocks-handling.html
                #
                # We can just return false here and let the caller retry and it'll work the next time.

                logging.info("Encountered database deadlock when trying to acquire lock. Returning false so the caller can try again.")

                return False
            else:
                raise FavoritesStoreException from e

        except Exception as e:

            cnx.rollback()
            raise FavoritesStoreException from e

        finally:
            cursor.close()
            cnx.close() 

    def _get_first_row(self, cursor):
        return cursor.fetchone()

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
