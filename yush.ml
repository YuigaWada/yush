open Ast

exception No_executables
exception Invalid_file_descriptor

let permission = 0o640
let red_meta = "\x1B[33m"
let nocolor_meta = "\x1B[0m"
let std = (Unix.stdin, Unix.stdout)

(* Path *)

let concat_path bf af =
  let tail str = String.sub str (String.length str - 2) 1 in
  if String.length bf == 0 then af
  else if tail bf == "/" then bf ^ af
  else bf ^ "/" ^ af

let resolve_fullpath path binpath =
  let accessible x =
    try
      Unix.access x [ Unix.X_OK ];
      true
    with _ -> false
  in

  let valid =
    List.filter_map
      (fun p ->
        if accessible (concat_path p binpath) then Some (concat_path p binpath)
        else None)
      path
  in
  match valid with x :: xs -> Some x | _ -> None
  
(* Redirect *)

let redirect red =
  let fds = [ Unix.stdin; Unix.stdout; Unix.stderr ] in
  let process fd path open_flags =
    let source = Unix.openfile path open_flags permission in
    if fd < 3 then Unix.dup2 source (List.nth fds fd)
    else raise Invalid_file_descriptor;
    source
  in

  match red with
  | InputRedirect (fd, path) -> process fd path [ O_RDONLY ]
  | OutputRedirect (fd, path) -> process fd path [ O_WRONLY; O_CREAT ]
  | OutputAppend path -> process 1 path [ O_WRONLY; O_APPEND ]

(* Execute *)

let execute path exe input output =
  match exe with
  | Command (binpath, args, redirects) -> (
      match resolve_fullpath path binpath with
      | None -> raise No_executables
      | Some fullpath -> (
          match Unix.fork () with
          | 0 ->
              (* Child process *)
              Unix.dup2 input Unix.stdin;
              Unix.dup2 output Unix.stdout;
              let fds = List.map redirect redirects in
              let args = Array.of_list (fullpath :: args) in
              let pid = Unix.execv fullpath args in
              List.iter Unix.close fds;
              Some pid
          | child_pid ->
              (* Parent process *)
              let _ = Unix.waitpid [] child_pid in
              Some child_pid))
  | CD dir ->
      let _ = Unix.chdir dir in
      None

let rec execute_all path pipes cmds pids =
  match pipes with
  | [] -> ()
  | pipe :: _pipes -> 
      let used_pipe_in, used_pipe_out = (List.length pids > 0, List.length _pipes > 0) in
      let input, _ = if used_pipe_in then pipe else std in
      let _, output = if used_pipe_out then List.hd _pipes else std in

      match cmds with
      | [] -> ()
      | x :: xs ->
          let pid = execute path x input output in
          if used_pipe_in then Unix.close input;
          if used_pipe_out then Unix.close output;
          execute_all path _pipes xs (pids @ [ pid ])

(* Main *)

let main stream =
  let process text =
    try
      let path = Str.split (Str.regexp ":") @@ Sys.getenv "PATH" in 
      let lexbuf = Lexing.from_string text in
      let coms = Parser.exes Lexer.lexer lexbuf in
      let pipes = List.init (List.length coms) (fun x -> Unix.pipe ()) in
      execute_all path pipes coms []
    with
    | Lexer.No_such_symbol -> Printf.printf "yush: invalid characters in the command.\n"
    | Invalid_file_descriptor -> Printf.printf "yush: invalid file descriptor.\n"
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
