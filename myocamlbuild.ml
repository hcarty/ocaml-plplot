(* OASIS_START *)
(* OASIS_STOP *)

let () =
  let additional_rules = function
    | After_rules ->
        (* Add correct PLplot compilation and link flags *)
        let plplot_clibs, oplplot_cflags, oplplot_clibs =
          let icc = Unix.open_process_in "pkg-config plplotd --cflags-only-I" in
          let icl = Unix.open_process_in "pkg-config plplotd --libs-only-l" in
          let icL = Unix.open_process_in "pkg-config plplotd --libs-only-L" in
          try
            let plplot_cflags = input_line icc in
            let plplot_clibs_l = input_line icl in
            let plplot_clibs_L = input_line icL in
            (* TODO: remove once split-function in generated code is fixed *)
            let rec split_string s =
              match try Some (String.index s ' ') with Not_found -> None with
              | Some pos ->
                  let sub = String.before s pos in
                  if sub <> "" then
                    sub :: split_string (String.after s (pos + 1))
                  else
                    split_string (String.after s (pos + 1))
              | None -> if s <> "" then [s] else []
            in
            let ocamlify ~ocaml_flag flags =
              let chunks = split_string flags in
              let cnv flag = [A ocaml_flag; A flag] in
              List.concat (List.map cnv chunks)
            in
            let split_flags flags =
              let chunks = split_string flags in
              let cnv flag = A flag in
              List.map cnv chunks
            in
            close_in icl;
            close_in icc;
            S (split_flags plplot_clibs_L @ split_flags plplot_clibs_l),
            S (ocamlify ~ocaml_flag:"-ccopt" plplot_cflags),
            S (
              ocamlify ~ocaml_flag:"-cclib" plplot_clibs_L @
              ocamlify ~ocaml_flag:"-cclib" plplot_clibs_l
            )
          with exn ->
            close_in icL;
            close_in icl;
            close_in icc;
            raise exn
        in
        flag ["compile"; "c"] oplplot_cflags;
        flag ["link"; "ocaml"; "library"] oplplot_clibs;
        flag ["oasis_library_plplot_cclib"; "ocamlmklib"; "c"] plplot_clibs;
        flag ["oasis_library_plplot_cclib"; "link"] oplplot_clibs
      | _ -> ()
  in
  dispatch (
    MyOCamlbuildBase.dispatch_combine
      [MyOCamlbuildBase.dispatch_default package_default; additional_rules])
