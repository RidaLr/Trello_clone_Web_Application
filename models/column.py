import datetime
from models.task import Task

class Column:
    def __init__(self, title, table_id):
        self.title = title
        self.table_id = table_id
        self.timestamp = datetime.datetime.now().timestamp()
        
        
    def insert(self, cursor):
        cursor.execute('''
          INSERT INTO column
          (title, table_id, timestamp)
          VALUES 
          (?, ?, ?)
        ''', (self.title, self.table_id, self.timestamp,)
        )
        
    def delete(self, cursor,rowid):
        cursor.execute('''
          DELETE FROM column
          WHERE rowid = ? 
        ''', (rowid,)
        )
        
    def __repr__(self):
        return "[Column title %s: for ID: %s]"%(
            self.title, 
            self.table_id
        )

    @classmethod
    def getMAx(cls, cursor):
        cursor.execute('''
         SELECT MAX(rowid) as maxi FROM column
        ''')
        return cursor.fetchall()
      
        
    @classmethod
    def create_table(cls, cursor):
        cursor.execute('DROP TABLE IF EXISTS column')

        cursor.execute('''
        CREATE TABLE column
        ( title TEXT NOT NULL,
        table_id INTEGER NOT NULL,
        timestamp DOUBLE,
        FOREIGN KEY (table_id) REFERENCES work(rowid)
        )''')

class ColumnForDisplay:
    def __init__(self, row):
        self.content = row['content']
        self.author_id = row['author_id']
        self.column_id = row ['column_id']
        self.rowid = row['rowid']
        self.title = row['title']
        self.table_id = row['table_id']
        self.visible = True
       
    
    @classmethod
    def getAll(cls, cursor):
      cursor.execute('''
          SELECT column.rowid,tasks.column_id, column.title, column.table_id,tasks.content, tasks.author_id
          FROM column
          JOIN tasks ON column.rowid=tasks.column_id
          ORDER BY tasks.timestamp DESC
      ''')
     # print("***************************************************************************************************************")
      #print(cursor.fetchall())
      #print("***************************************************************************************************************")
      return [ cls(row) for row in cursor.fetchall() ]