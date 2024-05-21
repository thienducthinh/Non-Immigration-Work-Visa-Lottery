import pymysql

class DBconnect(object):
    def __init__(self):
        self.dbconnection = pymysql.connect(
        host= "localhost",
        port=int(3306),
        user="root",
        passwd="YourPassword") # Change the password to your own MySQL password
        
        self.dbcursor = self.dbconnection.cursor()

    def commit_db(self):
        self.dbconnection.commit()
    
    def close_db(self):
        self.dbcursor.close()
        self.dbconnection.close()
