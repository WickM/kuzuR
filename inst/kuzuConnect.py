import kuzu

def kuzuConnect_py (path,read_only):
  db = kuzu.Database(path, read_only=read_only)
  conn = kuzu.Connection(db)
  return(conn)
