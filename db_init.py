import sqlite3

from models.user import User
from models.task import Task
from models.column import Column
from models.work import Work

def make_dicts(cursor, row):
    return dict((cursor.description[idx][0], value)
                for idx, value in enumerate(row))

  
db = sqlite3.connect('.data/db.sqlite')
db.row_factory = make_dicts

cur = db.cursor()

User.create_table(cur)
Task.create_table(cur)
Column.create_table(cur)
Work.create_table(cur)


users = [
    User("Rida", "rida@trello.com", "12345", "Admin"),
    User("Pavel", "pavel@trello.com", "12345", "Admin"),
    User("Toto", "toto@trello.com", "12345", "Collaborator"),
]

tasks = [
    Task(content="Do homework", author_id="rida@trello.com", column_id=1),
    Task(content="Task1111", author_id="rida@trello.com",column_id=2),
    Task(content="Test", author_id="rida@trello.com",column_id=1),
    Task(content="Do AWS project", author_id="pavel@trello.com", column_id=1),
    Task(content="Algo project", author_id="toto@trello.com", column_id=3),
]

tables = [
    Work(title="AWS Project", creator_id="rida@trello.com"),
    Work(title="Algorithm project", creator_id="pavel@trello.com"),
    Work(title="Sohier project", creator_id="toto@trello.com"),
]

columns = [
    Column(title="ToDo", table_id=1),
    Column(title="InProgress",table_id=1),
    Column(title="Done", table_id=2),
]



for user in users:
    user.insert(cur)

for table in tables:
    table.insert(cur)
    
for column in columns:
    column.insert(cur)

for task in tasks:
    task.insert(cur)


    

    
db.commit()

print("The following users has been inserted into the DB"
      " (all the passwords are 12345):")

for user in users:
    # uses the magic __repr__ method
    print("\t", user)
    
print()
print("Here are the posts inserted:")
for task in tasks:
    print("\t", task)
    
print()
print("Here are the tables inserted:")
for table in tables:
    print("\t", table)
    
print()
print("Here are the columns inserted:")
for column in columns:
    print("\t", column)