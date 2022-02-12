{
 open Parser  
 exception No_such_symbol

 let pop_head s = String.sub s 1 @@ (String.length s) - 1
 let pop_tail s = String.sub s 0 @@ (String.length s) - 1
 let crop_str s = pop_head @@ pop_tail s
}

let digit = ['0'-'9']
let str = ['a'-'z' 'A'-'Z' '_' '.' '/' '-' '~'] ['a'-'z' 'A'-'Z' '0'-'9' '.' '/' '-']*

rule lexer = parse
| "cd" { CD }
| str as text              { STR text }
| '\"'[^'\"']*'\"' as str { QSTR (crop_str str) }
| '\''[^'\'']*'\'' as str { QSTR (crop_str str) }
| digit+'>' as str { FDREDOUT (int_of_string @@ pop_tail str) }
| digit+ as num  { NUM (int_of_string num) }
| '|' { PIPE }
| '>' { REDOUT }
| '<' { REDIN }
| eof                     { EOF }
| [' ' '\t' ]             { lexer lexbuf }
| _                       { raise No_such_symbol }