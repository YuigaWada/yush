type path = string

type file_descriptor = int
type redirect = InputRedirect of file_descriptor * string 
              | OutputRedirect of file_descriptor * string (* fd_old -> fd_new *)
              | OutputAppend of string
type redirects = redirect list

type arg = string
type args = string list

type exe = Command of string * args * redirects
         | CD of string
type exes = exe list