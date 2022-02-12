type file_descriptor = int
type file = Path of string  
          | FileDescriptor of file_descriptor 
type redirect = InputRedirect of file_descriptor * file 
              | OutputRedirect of file_descriptor * file (* fd_old -> fd_new *)
              | OutputAppend of file
type redirects = redirect list

type arg = string
type args = string list

type exe = Command of string * args * redirects
         | CD of string
type exes = exe list