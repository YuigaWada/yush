%{

open Printf
open Ast

let crop_str s = String.sub s 1 @@ (String.length s) - 2
%}

/* File parser.mly */
%token <int> NUM
%token <string> STR SSTR DSTR
%token PIPE EOF SPACE CD
%type <Ast.exes> exes

%start exes           /* the entry point */

%%


exes : exe PIPE exes EOF {[$1] @ $3}
     | exe EOF {[$1]}
     | EOF {[]}
     ;

exe : STR args { Command($1,$2) }
    | CD args { CD(if List.length $2 > 0 then List.nth $2 0 else "./") }
    ;

args : {[]}
     | STR args {[$1]@$2}
     | SSTR args {[crop_str $1]@$2}
     | DSTR args {[crop_str $1]@$2}
     | NUM args {[string_of_int $1]@$2}
     ;

%%