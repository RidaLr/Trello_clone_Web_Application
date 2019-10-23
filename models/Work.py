import datetime

class Work:
    def __init__(self, title, creator_id):
        self.title = title
        self.creator_id = creator_id
        
    def insert(self, cursor):
        cursor.execute('''
          INSERT INTO work 
          ( title,
            creator_id
          )
          VALUES 
          ( ?, ?)
        ''', (self.title, self.creator_id)
        )
        
    def __repr__(self):
        return "[Table : %s By: %s]"%(
            self.title,
            self.author_id
        )

    @classmethod
    def create_table(cls, cursor):
        cursor.execute('DROP TABLE IF EXISTS tasks')

        cursor.execute('''
        CREATE TABLE Work
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
    