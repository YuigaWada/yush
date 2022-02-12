{
 open Parser  
 exception No_such_symbol
}

let digit = ['0'-'9']
let str = ['a'-'z' 'A'-'Z' '_' '.' '/' '-' '~'] ['a'-'z' 'A'-'Z' '0'-'9' '.' '/' '-']*

rule lexer = parse
| "cd" { CD }
| str as text              { STR text }
| '\"'[^'\"']*'\"' as str { QSTR str }
| '\''[^'\'']*'\'' as str { QSTR str }
| digit+'>' as str { FDREDOUT str }
| digit+ as num  { NUM (int_of_string num) }
| '|' { PIPE }
| '>' { REDOUT }
| '<' { REDIN }
| eof                     { EOF }
| [' ' '\t' ]             { lexer lexbuf }
| _                       { raise No_such_symbol }