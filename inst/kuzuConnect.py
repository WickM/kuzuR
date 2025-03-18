import kuzu

def kuzuConnect_py (path):
  db = kuzu.Database(path)
  conn = kuzu.Connection(db)
  return(conn)
