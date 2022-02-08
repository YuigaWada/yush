type binpath = string
type arg = string
type args = string list

type exe = Command of string * args
         | CD of string
type exes = exe list