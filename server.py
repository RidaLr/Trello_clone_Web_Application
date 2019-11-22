from flask import Flask, render_template, request, session, g, redirect, url_for, jsonify
import flask_socketio
import flask_login
import sqlite3

from models.user import User, UserForLogin, ConnectedUser
from models.task import Task, TaskForDisplay
from models.work import Work, WorkForDisplay
from models.column import Column, ColumnForDisplay

DATABASE = '.data/db.sqlite'
app = Flask(__name__)
app.secret_key = 'mysecret!'
io = flask_socketio.SocketIO(app)

login_manager = flask_login.LoginManager()
login_manager.init_app(app)
login_manager.login_view = 'login_get'

@login_manager.user_loader
def load_user(email):
    db = get_db()
    cur = db.cursor()
    return UserForLogin.getByEmail(cur, email)

##############################################################################
#                BOILERPLATE CODE (you can essentially ignore this)          #
##############################################################################

def get_db():
    """Boilerplate code to open a database
    connection with SQLite3 and Flask.
    Note that `g` is imported from the
    `flask` module."""
    db = getattr(g, '_database', None)
    if db is None:
        db = g._database = sqlite3.connect(DATABASE)
        db.row_factory = make_dicts
    return db

def make_dicts(cursor, row):
    return dict((cursor.description[idx][0], value)
                for idx, value in enumerate(row))

@app.teardown_appcontext
def close_connection(exception):
    """Boilerplate code: function called each time 
    the request is over."""
    db = getattr(g, '_database', None)
    if db is not None:
        db.close()
        
##############################################################################
#                APPLICATION CODE (read from this point!)                    #
##############################################################################

@app.route("/")
@flask_login.login_required
def home():
    db = get_db()
    cur = db.cursor()
    
    cur.execute('''SELECT rowid,* FROM column''')
    columns = cur.fetchall()
    
    cur.execute('''SELECT * FROM tasks,column where tasks.column_id=column.rowid''')
    tasks = cur.fetchall()
    
    cur.execute('''SELECT rowid, * FROM work where creator_id=? ORDER BY work.timestamp DESC''',(flask_login.current_user.get_id(),))
    works=cur.fetchall()
    
    return render_template(
      'index.html',
      users=UserForLogin.getAll(cur),
      columns=columns,
      tasks=tasks,
      works=WorkForDisplay.getAll(cur),
    )
  #return render_template('index.html')

@app.route("/login", methods=['POST'])
def login_post():
    email = request.form.get('email')
    password = request.form.get('password')
    remember = request.form.get('remember_me')
    if not email or not password:
        return render_template(
          'login.html',
          error_msg="Please provide your email and your password.",
        )

    db = get_db()
    cur = db.cursor()
    
    user = UserForLogin.getByEmail(cur, email)
    if user is None or not user.check_password(password):
        return render_template(
          'login.html',
          error_msg="Authentication failed",
        )

    flask_login.login_user(user, remember=remember)
    return redirect(url_for('home'))

@app.route('/login', methods=['GET'])
def login_get():
    return render_template('login.html')

  
@app.route('/signup', methods=['GET'])
def signup_get():
    return render_template('signup.html')

@app.route("/signup", methods=['POST'])
def signup_post():
    email = request.form.get('email')
    name = request.form.get('name')
    password1 = request.form.get('password1')
    password2 = request.form.get('password2')
    if not email or not name or not password1 or not password2:
        return render_template(
          'signup.html',
          error_msg="Please provide your email, name and password.",
        )


    if password1 != password2:
        return render_template(
          'signup.html',
          error_msg="The passwords do not match!",
        )
      
    user = User(name=name, email=email, password=password1)
    db = get_db()
    cur = db.cursor()
    try:
        user.insert(cur)
    except sqlite3.IntegrityError:
        return render_template(
          'signup.html',
          error_msg="This email is already signed up.",
        )
    
    db.commit()
    
    return redirect(url_for('login_get'))

@app.route('/logout', methods=['GET'])
@flask_login.login_required
def logout():
    flask_login.logout_user()
    return redirect(url_for('login_get'))
  
@app.route('/columns')
def displayColumnsForWork():
  print("you are on work")
  
  
@app.route('/is-email-used/<email>')
def is_email_used(email):
    db = get_db()
    cur = db.cursor()
    
    user = UserForLogin.getByEmail(cur, email)
    free = user is None
        
    return jsonify({"email": email, "free": free})
    

@app.route('/AddColumn/', methods=['POST'])
def addcolonne():
  col=request.form['column']
  idtab=request.form['idtabe']
  column=Column(title=col,table_id=idtab)
  db = get_db()
  cur = db.cursor()
  column.insert(cur)
  db.commit()
  
  return redirect(url_for('home'))

@app.route('/DeleteColumn/', methods=['POST'])
def deletecolonne():
  rowid=request.form['rowid']
  column=Column(rowid)
  db = get_db()
  cur = db.cursor()
  column.delete(cur,rowid)
  db.commit()
  return redirect(url_for('home'))


"""##########################################TODO###############################"""
@app.route('/delete-task/', methods=['POST'])
def ShowWork():
  id_ta=request.form['idWork']
  db = get_db()
  cur = db.cursor()
    
  cur.execute('''SELECT * FROM tasks,column where tasks.column_id=column.rowid''')
  tasks = cur.fetchall()
    
  return render_template('index.html',users=UserForLogin.getAll(cur),columns=columns,tasks=tasks,works=WorkForDisplay.getAll(cur),)
  
  
@app.route('/add-task/', methods=['POST'])
def addtache():
  tache=request.form['task']
  id_col=request.form['colid']
  id_ta=request.form['idt']
  task=Task(content=tache,column_id=id_col,author_id=flask_login.current_user.get_id())
  db = get_db()
  cur = db.cursor()
  task.insert(cur)
  db.commit()
  return redirect(url_for('home'))

@app.route('/Add-Work/',methods=['POST'])
def addtable():
  table=request.form['work']
  work=Work(title=table,creator_id=flask_login.current_user.get_id())
  db = get_db()
  cur = db.cursor()
  work.insert(cur)
  db.commit()
  return redirect(url_for('home'))

@app.route('/addTable/', methods=['POST'])
@flask_login.login_required
def posts_table():
    content = request.json["content"]
    work = Work(title=content, creator_id=flask_login.current_user.get_id())
    print(content)
    db = get_db()
    cur = db.cursor()
    work.insert(cur)
    db.commit()

    return "ok", 201
  
  #---------------------------TODO
@app.route('/tasks/', methods=['POST'])
@flask_login.login_required
def posts_task():
    content = request.json["content"]
    task = Task(content=content, author_id=flask_login.current_user.get_id(),column_id="ToDO",status="ToDO")#TODO modify this shit
    print(content)
    db = get_db()
    cur = db.cursor()
    task.insert(cur)
    db.commit()

    return "ok", 201


@app.route("/works/")
def search():
  db = get_db()
  cur = db.cursor()
  #cur.execute("SELECT key, url FROM shortcuts WHERE url LIKE ?", ('%' + query + '%',))
  works = WorkForDisplay.getAll(cur)
  return jsonify(works=works)


  
## Rowid -> User
CONNECTED_USERS = {}

def get_user_status(user_rowid):
    user = CONNECTED_USERS.get(user_rowid)
    if user is None:
        return 'DISCONNECTED'
    return user.status

def broadcast_user_list(cursor):
    print("send users")
    io.emit('userlist', [
        { "name": u.name,
          "rowid": u.rowid,
          "status": get_user_status(u.rowid),
        }
        for u in UserForLogin.getAll(cursor)
      ]
  , broadcast=True)
    print("users sent")
    for u in UserForLogin.getAll(cursor):
      print(u.name)

def broadcast_task_list(cursor):
    print("send tasks")
    io.emit('tasklist', [
        { "author_name": t.author_name,
          "content": t.content,
          "date": t.date.strftime("%m/%d/%Y"),
          "rowid": t.rowid,
          "column_id": t.column_id,
          "visible" : True,
        }
        for t in TaskForDisplay.getAll(cursor)
      ]
  , broadcast=True)
    print("tasks sent")
    for i in TaskForDisplay.getAll(cursor):
      print(i.content)
      
def broadcast_column_list(cursor):
    print("send columns")
    io.emit('columnlist', [
        { "title": l.title,
          "rowid": l.rowid,
          "table_id": l.table_id,
          "content" : l.content,
          "author_id" : l.author_id,
         "column_id": l.column_id,
         "visible" : True,
        }
        for l in ColumnForDisplay.getAll(cursor)
      ]
    , broadcast=True)
    print("columns sent")

    
def broadcast_work_list(cursor):
    print("send works")
    io.emit('worklist', [
        { "title": w.title,
          "authorName": w.creator_id,
          "date": w.timestamp.strftime("%m/%d/%Y"),
          "rowid": w.rowid,
        }
        for w in WorkForDisplay.getAll(cursor)
      ]
  , broadcast=True)
    print("works sent")
  
  
@io.on('connect')
def ws_connect():
    if not flask_login.current_user.is_authenticated:
        raise ConnectionRefusedError('unauthorized!')

    user = flask_login.current_user
    CONNECTED_USERS[user.rowid] = ConnectedUser(user.rowid, user.name, request.sid, user.role)
    
    db = get_db()
    cur = db.cursor()
  
    broadcast_user_list(cur)
    #broadcast_task_list(cur)
    #broadcast_work_list(cur)
    ##broadcast_column_list(cur)
   # broadcast_column_list_by_id(cur, s)

@io.on('disconnect')
def ws_disconnect():
    user = CONNECTED_USERS[flask_login.current_user.rowid]
    
    del CONNECTED_USERS[flask_login.current_user.rowid]
    
    db = get_db()
    cur = db.cursor()    
    broadcast_user_list(cur)

if __name__ == '__main__':
    io.run(app, debug=True)
"""if __name__ == '__main__':
    app.run(debug=True)"""

