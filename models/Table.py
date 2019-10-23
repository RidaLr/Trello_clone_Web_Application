import datetime

class Table:
    def __init__(self, title):
        self.title = title
        
    def insert(self, cursor):
        cursor.execute('''
          INSERT INTO column 
          ( title
          )
          VALUES 
          ( ?)
        ''', (self.content, self.author_id, self.timestamp, self.status)
        )
        
    def __repr__(self):
        return "[Post by %s at %s: %s %s]"%(
            self.author_id, 
            str(datetime.datetime.fromtimestamp(self.timestamp)),
            self.content[:50],
            self.status
        )

    @classmethod
    def create_table(cls, cursor):
        cursor.execute('DROP TABLE IF EXISTS tasks')

        cursor.execute('''
        CREATE TABLE tasks
        ( author_id TEXT NOT NULL
        , content TEXT
        , timestamp DOUBLE
        , status TEXT
        , FOREIGN KEY (author_id) REFERENCES users(email)
        )''')

class TaskForDisplay:
    def __init__(self, row):
        self.author_name = row['author_name']
        self.date = datetime.datetime.fromtimestamp(row['timestamp'])
        self.content = row['content']
        self.status = row['status']
   
    
    @classmethod
    def getAll(cls, cursor):
      cursor.execute('''
          SELECT name AS author_name, content, timestamp ,status
          FROM tasks
          JOIN users ON author_id=email
          ORDER BY timestamp DESC
      ''')
      return [ cls(row) for row in cursor.fetchall() ]
    