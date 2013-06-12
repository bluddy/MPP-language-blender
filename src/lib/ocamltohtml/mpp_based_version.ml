
let html_of_ocaml filename out =
  let ic = open_in filename in
    Ocamltohtml_lexer.oc := out;
    Printf.fprintf out "<pre class='ocaml'>\n";
    try
      let lexbuf = Lexing.from_channel ic in
        while true do
          ignore (Ocamltohtml_lexer.token lexbuf)
        done
    with Ocamltohtml_lexer.Eof ->
      Printf.fprintf out "</pre>";
      (try close_in ic with _ -> ())

let html_of_ocaml_default_css out =
  Printf.fprintf out "<style type='text/css'>/* <!-- */
.ocaml{background-color:#EEE}
.kwd{color: green;}
.kwd1{color: red;}
.kwd2{color: blue;}
.str{color: navy;}
.mname{color: orange;}
.com1{color: violet;}
.com2{color: fuchsia;}
.error{background-color:pink;}
/* --> */</style>\n%!"

let html_of_ocamlc args out =
  let tmp = Filename.temp_file (* ~temp_dir:"/tmp" *) "tmp" "plop" in
  let tmp1 = Filename.temp_file (* ~temp_dir:"/tmp" *) "tmp" "plop" in
  match Sys.command (args ^ " > " ^ tmp1 ^ " 2> " ^ tmp) with
    | 2 ->
        let open Mpp_charstream in
(*         let () = Mpp_actions.cat out tmp in *)
        let cs = charstream_of_inchannel tmp (open_in tmp) in
        let _ = read_until '"' cs in
        let _ = charstream_take_n 1 cs in
        let filename = read_until '"' cs in
        let _ = charstream_take_n 8 cs in
        let line = int_of_string (read_until ',' cs) in
        let _ = charstream_take_n 13 cs in
        let colstart = int_of_string (read_until '-' cs) in
        let _ = charstream_take_n 1 cs in
        let colend = int_of_string (read_until ':' cs) in
        let fcs = charstream_of_inchannel filename (open_in filename) in
        let () = 
          for i = 2 to line do
            ignore(read_until '\n' fcs)
          done;
          ignore(fcs.take())
        in
        let s = charstream_take_n (colstart) (fcs) in
        let () = Printf.fprintf out "<pre class='ocaml'>" in
        let () = Ocamltohtml_lexer.oc := out in
        let () = Ocamltohtml_lexer.html_escape s in
        let es = charstream_take_n (colend - colstart + 1) fcs in
        let el = read_until '\n' fcs in
        let lexbuf1 = Lexing.from_string (es) in
        let lexbuf2 = Lexing.from_string (el) in
        let () =
          Printf.fprintf out "<span class='error'>";
          try while true do ignore(Ocamltohtml_lexer.token lexbuf1) done
          with Ocamltohtml_lexer.Eof -> 
            Printf.fprintf out "</span>";
            try while true do ignore(Ocamltohtml_lexer.token lexbuf2) done
            with Ocamltohtml_lexer.Eof -> ()
        in
        let () =
          ignore(cs.take());
          output_charstream out cs;
          Printf.fprintf out "</pre>\n"
        in ()
    | 0 -> ()
    | n -> 
        Printf.fprintf out "<pre class='error'>Command %s returned with code %d, I don't know what to do with it. Here's the output:\n" args n;
        Mpp_actions.cat out tmp1;
        Printf.fprintf out "</span>"