import flask_login
from werkzeug.security import generate_password_hash, check_password_hash

class User:
    def __init__(self, name, email, password, role):
        self.name = name
        self.email = email
        self.set_password(password)
        self.role = role

    def set_password(self, password):
        self.password_hash = generate_password_hash(password)
    

    def insert(self, cursor):
        cursor.execute('''
          INSERT INTO users 
          ( name
          , email
          , password_hash
          , role
          )
          VALUES 
          ( ?, ?, ?, ?)
        ''', (self.name, self.email, self.password_hash, self.role)
        )
        
    def __repr__(self):
        return "[User %s<%s>]"%(self.name, self.email)
        
    @classmethod
    def create_table(cls, cursor):
        cursor.execute('DROP TABLE IF EXISTS users')

        cursor.execute('''
        CREATE TABLE users      
        ( name TEXT NOT NULL
        , password_hash TEXT NOT NULL
        , email TEXT NOT NULL PRIMARY KEY
        , role TEXT
        )''')

class UserForLogin(flask_login.UserMixin):
    def __init__(self, row):
        self.email = row['email']
        self.password_hash = row['password_hash']
        self.name = row['name']
        self.role = row['role']
        self.rowid = row['rowid']
    
    def check_password(self, password):
        return check_password_hash(self.password_hash, password)
    
    def get_id(self):
        return self.email
      
    @classmethod
    def getByEmail(cls, cursor, email):
        cursor.execute('''
            SELECT rowid, email, password_hash, name, role
            FROM users
            WHERE email = ?
        ''', (email))

        row = cursor.fetchone()
        if row is None:
            return None
        
        return cls(row)
    
    @classmethod
    def getAll(cls, cursor):
      cursor.execute('SELECT rowid, name, email, password_hash, role FROM users')
      return [ cls(row) for row in cursor.fetchall() ]

class ConnectedUser:
    def __init__(self, rowid, name, role, socket_id):
        self.rowid = rowid
        self.name = name
        self.role = role
        self.socket_id = socket_id
        self.status = 'AVAILABLE'


  