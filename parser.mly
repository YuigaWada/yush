%{

open Printf
open Ast

let pop_head s = String.sub s 1 @@ (String.length s) - 1
let pop_tail s = String.sub s 0 @@ (String.length s) - 1
let crop_str s = pop_head @@ pop_tail s
%}

/* File parser.mly */
%token <int> NUM
%token <string> STR SSTR DSTR NRRED
%token PIPE EOF SPACE CD LRED RRED
%type <Ast.exes> exes

%start exes           /* the entry point */

%%


exes : exe PIPE exes EOF {[$1] @ $3}
     | exe EOF {[$1]}
     | EOF {[]}
     ;

exe : STR args redirects { Command($1,$2,$3) }
    | CD args { CD(if List.length $2 > 0 then List.nth $2 0 else "./") }
    ;

args : {[]}
     | STR args {[$1]@$2}
     | SSTR args {[crop_str $1]@$2}
     | DSTR args {[crop_str $1]@$2}
     | NUM args {[string_of_int $1]@$2}
     ;

redirects : {[]}
          | LRED STR redirects {[InputRedirect(0,$2)]@$3}
          | RRED STR redirects {[OutputRedirect(1,$2)]@$3}
          | NRRED STR redirects {[OutputRedirect(int_of_string @@ pop_tail $1,$2)]@$3}
          | RRED RRED STR redirects {[OutputAppend($3)]@$4}
          ;

%%