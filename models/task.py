import datetime

class Task:
    def __init__(self, content, author_id, column_id):
        self.content = content
        self.author_id = author_id
        self.column_id = column_id
        self.timestamp = datetime.datetime.now().timestamp()
        
    def insert(self, cursor):
        cursor.execute('''
          INSERT INTO tasks 
          ( content
          , author_id
          , column_id
          , timestamp
          )
          VALUES 
          ( ?, ?, ?, ?)
        ''', (self.content, self.author_id, self.column_id, self.timestamp)
        )
        
    def __repr__(self):
        return "[Post by %s at %s: %s]"%(
            self.author_id, 
            str(datetime.datetime.fromtimestamp(self.timestamp)),
            self.content[:50]
        )

    @classmethod
    def create_table(cls, cursor):
        cursor.execute('DROP TABLE IF EXISTS tasks')

        cursor.execute('''
        CREATE TABLE tasks
        ( author_id TEXT NOT NULL
        , column_id INTEGER NOT NULL
        , content TEXT
        , timestamp DOUBLE
        , FOREIGN KEY (author_id) REFERENCES users(email)
        , FOREIGN KEY (column_id) REFERENCES column(rowid)
        )''')

class TaskForDisplay:
    def __init__(self, row):
        #self.author_name = row['author_name']
       # self.rowid = row['rowid']
        #self.date = datetime.datetime.fromtimestamp(row['timestamp'])
        self.content = row['content']
        self.column_id=row['column_id']
    
    @classmethod
    def getAll(cls, cursor):
      cursor.execute('''
          SELECT * FROM tasks,column where tasks.column_id=column.rowid
      ''')
      return [ cls(row) for row in cursor.fetchall() ]
    
    
    
"""SELECT title,content, tasks.timestamp ,status
          FROM tasks
          JOIN column ON column_id=column.rowid
          ORDER BY tasks.timestamp DESC"""