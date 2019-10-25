import datetime

class Column:
    def __init__(self, title,table_id):
        self.title = title
        
    def insert(self, cursor):
        cursor.execute('''
          INSERT INTO column
          ( title )
          VALUES 
          ( ?)
        ''', (self.title)
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
        cursor.execute('DROP TABLE IF EXISTS column')

        cursor.execute('''
        CREATE TABLE column
        ( title TEXT NOT NULL
        )''')

class ColumnForDisplay:
    def __init__(self, row):
        self.id = row['rowid']
        self.title = row['title']
   
    
    @classmethod
    def getAll(cls, cursor):
      cursor.execute('''
          SELECT rowid, title
          FROM column c
          LEFT JOIN task t ON c.rowid=t.column_id
          ORDER BY t.timestamp ASC
      ''')
      return [ cls(row) for row in cursor.fetchall() ]