Running "C:/Program Files/R/R-4.5.0alpha/bin/x64/Rcmd.exe" INSTALL "C:\Users\krist\AppData\Local\Temp\RtmpQbYx7u/kuzuR_0.1.0.tar.gz" \
  --install-tests 
* installing to library 'C:/Users/krist/AppData/Local/R/win-library/4.5'
* installing *source* package 'kuzuR' ...
** this is package 'kuzuR' version '0.1.0'
** using staged installation
** libs
using C++ compiler: 'G__~1.EXE (GCC) 13.2.0'
using C++20
g++  -std=gnu++20 -I"C:/PROGRA~1/R/R-45~1.0AL/include" -DNDEBUG -I. -DKUZU_STATIC_DEFINE -I'C:/Users/krist/AppData/Local/R/win-library/4.5/Rcpp/include'   -I"C:/rtools44/x86_64-w64-mingw32.static.posix/include"      -O2 -Wall  -mfpmath=sse -msse2 -mstackrealign    -c RcppExports.cpp -o RcppExports.o
RcppExports.cpp:14:12: error: 'Database' was not declared in this scope
   14 | Rcpp::XPtr<Database> create_kuzu_database(Rcpp::Nullable<std::string> db_path);
      |            ^~~~~~~~
RcppExports.cpp:14:20: error: template argument 1 is invalid
   14 | Rcpp::XPtr<Database> create_kuzu_database(Rcpp::Nullable<std::string> db_path);
      |                    ^
RcppExports.cpp:14:20: error: template argument 3 is invalid
make: *** [C:/PROGRA~1/R/R-45~1.0AL/etc/x64/Makeconf:296: RcppExports.o] Error 1
ERROR: compilation failed for package 'kuzuR'
* removing 'C:/Users/krist/AppData/Local/R/win-library/4.5/kuzuR'
* restoring previous 'C:/Users/krist/AppData/Local/R/win-library/4.5/kuzuR'
Warning message:
In file.copy(savedcopy, lib, recursive = TRUE) :
  problem copying C:\Users\krist\AppData\Local\R\win-library\4.5\00LOCK\Rcpp\libs\x64\Rcpp.dll to C:\Users\krist\AppData\Local\R\win-library\4.5\Rcpp\libs\x64\Rcpp.dll: Permission denied
