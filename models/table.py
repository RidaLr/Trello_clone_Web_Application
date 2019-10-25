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
        return "[Work : %s By: %s]"%(
            self.title,
            self.author_id
        )

    @classmethod
    def create_table(cls, cursor):
        cursor.execute('DROP TABLE IF EXISTS work')

        cursor.execute('''
        CREATE TABLE work
        ( creator_id TEXT NOT NULL
        , title TEXT
        , FOREIGN KEY (creator_id) REFERENCES users(email)
        )''')

class WorkForDisplay:
    def __init__(self, row):
        self.author_name = row['author_name']
        self.dtitle = title
   
    
    @classmethod
    def getAll(cls, cursor):
      cursor.execute('''
          SELECT name AS author_name, title
          FROM work
          JOIN users ON creator_id=email
          ORDER BY timestamp DESC
      ''')
      return [ cls(row) for row in cursor.fetchall() ]
    */