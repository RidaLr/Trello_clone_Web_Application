import datetime

class Column:
    def __init__(self, title, table_id):
        self.title = title
        self.table_id = table_id
        
    def insert(self, cursor):
        cursor.execute('''
          INSERT INTO column
          (title, table_id)
          VALUES 
          (?, ?)
        ''', (self.title, self.table_id,)
        )
        
    def __repr__(self):
        return "[Column title %s: for ID: %s]"%(
            self.title, 
            self.table_id
        )

    @classmethod
    def create_table(cls, cursor):
        cursor.execute('DROP TABLE IF EXISTS column')

        cursor.execute('''
        CREATE TABLE column
        ( title TEXT NOT NULL,
        table_id INTEGER NOT NULL,
        FOREIGN KEY (table_id) REFERENCES work(table_id)
        )''')

class ColumnForDisplay:
    def __init__(self, row):
        self.id = row['rowid']
        self.title = row['title']
        self.table_id = row['table_id']
   
    
    @classmethod
    def getAll(cls, cursor):
      cursor.execute('''
          SELECT rowid, title
          FROM column c
          LEFT JOIN task t ON c.rowid=t.column_id
          ORDER BY t.timestamp ASC
      ''')
      return [ cls(row) for row in cursor.fetchall() ]