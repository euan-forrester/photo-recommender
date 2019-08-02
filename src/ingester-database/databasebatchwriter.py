import mysql.connector
import logging

class DatabaseBatchWriterException(Exception):
    pass

class DatabaseBatchWriter:

    def __init__(self, username, password, host, port, database, max_retries, metrics_helper):
        self.cnx = mysql.connector.connect(user=username, password=password, host=host, port=port, database=database)

        self.cnx.autocommit = False

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