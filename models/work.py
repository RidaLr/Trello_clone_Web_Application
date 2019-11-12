import datetime

class Work:
    def __init__(self, title, creator_id):
        self.title = title
        self.creator_id = creator_id
        self.timestamp = datetime.datetime.now().timestamp()
        
    def insert(self, cursor):
        cursor.execute('''
          INSERT INTO work 
          ( title,
            creator_id,
            timestamp
          )
          VALUES 
          ( ?, ?, ?)
        ''', (self.title, self.creator_id, self.timestamp)
        )
        
    def __repr__(self):
        return "[Work : %s]"%(
            self.title,
        )

    @classmethod
    def create_table(cls, cursor):
        cursor.execute('DROP TABLE IF EXISTS work')

        cursor.execute('''
        CREATE TABLE work
        ( creator_id TEXT NOT NULL
        , title TEXT,
        timestamp DOUBLE
        , FOREIGN KEY (creator_id) REFERENCES users(email)
        )''')

class WorkForDisplay:
    def __init__(self, row):
        #self.author_name = row['author_name']
        self.title = row['title']
        self.creator_id = row['creator_id']
        self.timestamp = datetime.datetime.fromtimestamp(row['timestamp'])
        self.rowid = row['rowid']
    
    
    @classmethod
    def getAll(cls, cursor):
      cursor.execute('''
          SELECT rowid, * FROM work ORDER BY work.timestamp DESC
      ''')
     # print("*************works*****************************************************")
     # print(cursor.fetchall() )
      return [ cls(row) for row in cursor.fetchall() ]
 