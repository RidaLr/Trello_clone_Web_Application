import datetime

class Column:
    def __init__(self, title,table_id):
        self.title = title
        self.table_id = table_id
        
    def insert(self, cursor):
        cursor.execute('''
          INSERT INTO column
          ( title
          , table_id
          )
          VALUES 
          ( ?, ?)
        ''', (self.title, self.column_id)
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