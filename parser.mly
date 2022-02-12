%{

open Printf
open Ast

%}

/* File parser.mly */
%token <int> NUM FDREDOUT
%token <string> STR QSTR
%token PIPE EOF SPACE CD REDIN REDOUT
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
     | QSTR args {[$1]@$2}
     | NUM args {[string_of_int $1]@$2}
     ;

redirects : {[]}
          | REDIN STR redirects {[InputRedirect(0,$2)]@$3}
          | REDOUT STR redirects {[OutputRedirect(1,$2)]@$3}
          | FDREDOUT STR redirects {[OutputRedirect($1,$2)]@$3}
          | REDOUT REDOUT STR redirects {[OutputAppend($3)]@$4}
          ;

%%