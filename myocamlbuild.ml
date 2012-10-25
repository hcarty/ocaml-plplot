(* OASIS_START *)
(* OASIS_STOP *)

let run_and_read = Ocamlbuild_pack.My_unix.run_and_read
let blank_sep_strings = Ocamlbuild_pack.Lexers.blank_sep_strings

let read_chunks cmd =
  blank_sep_strings (
    Lexing.from_string (
      run_and_read cmd
    )
  )

let () =
  let additional_rules = function
    | After_rules ->
        (* Add correct PLplot compilation and link flags *)
        let plplot_clibs, oplplot_cflags, oplplot_clibs =
          let plplot_cflags = read_chunks "pkg-config plplotd --cflags-only-I" in
          let plplot_clibs_l = read_chunks "pkg-config plplotd --libs-only-l" in
          let plplot_clibs_L = read_chunks "pkg-config plplotd --libs-only-L" in
          let ocamlify ~ocaml_flag flags =
            let cnv flag = [A ocaml_flag; A flag] in
            List.concat (List.map cnv flags)
          in
          let split_flags flags =
            let cnv flag = A flag in
            List.map cnv flags
          in
          S (split_flags plplot_clibs_L @ split_flags plplot_clibs_l),
          S (ocamlify ~ocaml_flag:"-ccopt" plplot_cflags),
          S (
            ocamlify ~ocaml_flag:"-cclib" plplot_clibs_L @
            ocamlify ~ocaml_flag:"-cclib" plplot_clibs_l
          )
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
