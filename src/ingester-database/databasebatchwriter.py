import mysql.connector
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

        # Curiously, our lowest time for an individual process to write to the database is slightly lower
        # with READ COMMITTED, with an overall average of 2.31s with our test dataset.
        # However, READ UNCOMMITTED comes in with an overall average of 2.63s with the same dataset.
        #
        # But, our overall system run time is significantly faster with READ UNCOMMITTED.
        # With READ COMMITTED, the average overall system runtime was 13.7s.
        # However, with READ UNCOMMITTED, the average overall system runtime was 6.7s.
        # I assume that READ UNCOMMITTED allows for more concurrency.

        # I've also tried experimenting with committing after every batch, rather than at the end, and large and small batch sizes.
        # No conclusive results yet due to imprecise measurements I think.

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

            except mysql.connector.errors.InternalError as e:
                # We seem to get occasional deadlock errors when having many processes writing lots to the database.
                # There doesn't seem to be a way to determine that this happened from the exception object other than to test
                # the string against "Deadlock found when trying to get lock".
                #
                # https://github.com/euan-forrester/photo-recommender/issues/34
                
                logging.info(f"Got MySQL InternalError {e} on retry {num_retries} of {self.max_retries}")
                error = e

            num_retries += 1

        if not success:
            metrics_helper.increment_count("DatabaseBatchWriterException")
            raise DatabaseBatchWriterException(f"Unable to write to database after {self.max_retries} retries") from error

        return result 

    def shutdown(self):
        self.cnx.commit()
        self.cursor.close()
        self.cnx.close()