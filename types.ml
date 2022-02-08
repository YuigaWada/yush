type tag = unit ref
type ty = INT | ARRAY of int * ty * tag | NAME of string * ty option ref | UNIT | NIL
