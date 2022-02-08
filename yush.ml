open Ast

exception No_executables

let red_meta = "\x1B[33m"
let nocolor_meta = "\x1B[0m"
let path = [ "/bin/"; "/usr/bin/" ]

(* Path *)

let resolve_fullpath path binpath =
  let accessible x =
    try
      Unix.access x [ Unix.X_OK ];
      true
    with _ -> false
  in

  let res =
    List.filter_map
      (fun p -> if accessible (p ^ binpath) then Some (p ^ binpath) else None)
      path
  in
  match res with x :: xs -> Some x | _ -> None

(* Execute *)

let execute path exe input output =
  match exe with
  | Command (binpath, args) -> (
      match resolve_fullpath path binpath with
      | None -> raise No_executables
      | Some fullpath -> (
          match Unix.fork () with
          | 0 ->
              (* Child process *)
              let args = Array.of_list (fullpath :: args) in

              Unix.dup2 input Unix.stdin;
              Unix.dup2 output Unix.stdout;
              Unix.execv fullpath args
          | child_pid ->
              (* Parent process *)
              let _ = Unix.waitpid [] child_pid in
              Some child_pid))
  | CD dir ->
      let _ = Unix.chdir dir in
      None

let rec execute_all path pipe cmds pids =
  let pipeRead, pipeWrite = pipe in
  let input = match List.length pids with 0 -> Unix.stdin | _ -> pipeRead in
  let output = match List.length cmds with 1 -> Unix.stdout | _ -> pipeWrite in

  match cmds with
  | [] -> ()
  | x :: xs -> execute_all path pipe xs (pids @ [ execute path x input output ])

(* Main *)

let main stream =
  let process text =
    try
      let lexbuf = Lexing.from_string text in
      let coms = Parser.exes Lexer.lexer lexbuf in
      let pipe = Unix.pipe () in
      execute_all path pipe coms []
    with
    | Lexer.No_such_symbol -> Printf.printf "yush: invalid characters in the command.\n"
    | _ -> Printf.printf "yush: command not found.\n"
  in
  Stream.iter process stream

let read_stream_line =
  let f _ =
    let curent_dir = Unix.getcwd () in
    Printf.printf "%s[%s]%s yush> " red_meta curent_dir nocolor_meta;
    try Some (read_line ()) with End_of_file -> exit 0
  in
  Stream.from f

let () =
  match Array.to_list Sys.argv with
  | [ _ ] -> main read_stream_line
  | _ ->
      Printf.fprintf stderr "Invalid format.\n";
      flush stderr;
      exit 1
