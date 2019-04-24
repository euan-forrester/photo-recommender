import mysql.connector

class DatabaseBatchWriter:

    def __init__(self, username, password, host, port, database):
        self.cnx = mysql.connector.connect(user=username, password=password, host=host, port=port, database=database)

        self.cnx.autocommit = False

        self.cursor = self.cnx.cursor()

    def batch_write(self, sql_insert, create_value_tuple, items):

        # Our SQL statement is of the form "INSERT INTO <table> (col1, col2, etc) VALUES (%s, %s, etc)"
        # and so we first need to transform each of our items into a tuple that puts val1, val2, etc in the correct order.

        value_tuples = []

        for item in items:
            value_tuples.append(create_value_tuple(item))

        self.cursor.executemany(sql_insert, value_tuples)

    def shutdown(self):
        self.cnx.commit()
        self.cursor.close()
        self.cnx.close()