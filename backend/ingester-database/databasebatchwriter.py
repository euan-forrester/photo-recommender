import mysql.connector
from mysql.connector import errorcode
from mysql.connector import errors
import logging

# Lots of good information about performance re bulk inserts here:
#
# - General inserts: https://dev.mysql.com/doc/refman/8.0/en/insert-optimization.html
# - InnoDB inserts: https://dev.mysql.com/doc/refman/8.0/en/optimizing-innodb-bulk-data-loading.html
# - Autoincrement specifics: https://dev.mysql.com/doc/refman/8.0/en/innodb-auto-increment-handling.html
# - Transaction type specifics: https://dev.mysql.com/doc/refman/8.0/en/innodb-transaction-isolation-levels.html

# Note that since we're using MySQL 8.0, it uses innodb_autoinc_lock_mode = 2 (“interleaved” lock mode) by default

# The big missing piece I see from those links is the UNIQUE constraint on this table, 
# but we can't currently disable that because we expect duplicates in our input

class DatabaseBatchWriterException(Exception):
    pass

class DatabaseBatchWriter:

    def __init__(self, username, password, host, port, database, max_retries, metrics_helper):
        self.cnx = mysql.connector.connect(user=username, password=password, host=host, port=port, database=database)

        self.cnx.autocommit = False

        # The 4 types of transactions are 'READ UNCOMMITTED', 'READ COMMITTED', 'REPEATABLE READ', and 'SERIALIZABLE'
        # https://dev.mysql.com/doc/connector-python/en/connector-python-api-mysqlconnection-start-transaction.html

        # We're just trying to get data into the database as fast as possible and don't care about ACID compliance
        # for these transactions, so pick the lowest isolation level.

        self.cnx.start_transaction(isolation_level="READ UNCOMMITTED")

        self.cursor = self.cnx.cursor()

        self.max_retries = max_retries

    def batch_write(self, sql_insert, create_value_tuple, items):

        # Our SQL statement is of the form "INSERT INTO <table> (col1, col2, etc) VALUES (%s, %s, etc)"
        # and so we first need to transform each of our items into a tuple that puts val1, val2, etc in the correct order.

        value_tuples = []

        for item in items:
            value_tuples.append(create_value_tuple(item))

        self._execute_with_retries(sql_insert, value_tuples)

    def commit_current_batches(self):
        self.cnx.commit()

    def _execute_with_retries(self, sql_insert, value_tuples):
       
        num_retries = 0
        result = None
        success = False
        error = None

        while (num_retries < self.max_retries) and not success:
            
            if num_retries > 0:
                logging.info("Retrying SQL query")

            try:
                result = self.cursor.executemany(sql_insert, value_tuples)
                success = True

            except errors.InternalError as e:

                error = e
              
                if e.errno == errorcode.ER_LOCK_DEADLOCK:
                    # We seem to get occasional deadlock errors when having many processes writing lots to the database.
                    # Just retry and see if it clears
                    
                    logging.info(f"Encountered deadlock on retry {num_retries} of {self.max_retries}")
                else:
                    logging.info(f"Got MySQL InternalError {e} on retry {num_retries} of {self.max_retries}")

            num_retries += 1

        if not success:
            metrics_helper.increment_count("DatabaseBatchWriterException")
            raise DatabaseBatchWriterException(f"Unable to write to database after {self.max_retries} retries") from error

        return result 

    def shutdown(self):
        self.commit_current_batches()
        self.cursor.close()
        self.cnx.close()