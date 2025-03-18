

kuzuConnect <- function(path=""){
  reticulate::source_python("inst/kuzuConnect.py")

  conn <- kuzuConnect_py(path = path)
  return(conn)
}
