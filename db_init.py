import sqlite3

from models.user import User
from models.task import Task

def make_dicts(cursor, row):
    return dict((cursor.description[idx][0], value)
                for idx, value in enumerate(row))

  
db = sqlite3.connect('.data/db.sqlite')
db.row_factory = make_dicts

cur = db.cursor()

User.create_table(cur)
Task.create_table(cur)


users = [
    User("Rida", "rida@trello.com", "12345", "Admin"),
    User("Pavel", "pavel@trello.com", "12345", "Admin"),
    User("Toto", "toto@trello.com", "12345", "Collaborator")
]

tasks = [
    Task(content="Do homework", author_id="rida@trello.com",status="ToDo"),
    Task(content="Do AWS project", author_id="pavel@trello.com",status="Done"),
]

for user in users:
    user.insert(cur)

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