import mysql.connector

class DatabaseBatchWriter:

    def __init__(self, username, password, host, port, database):
        self.cnx = mysql.connector.connect(user=username, password=password, host=host, port=port, database=database)


    def shutdown(self):
        self.cnx.close()