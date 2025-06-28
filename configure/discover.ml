module C = Configurator.V1

let plplot_test = {|
#include <plplot.h>

int main()
{
  printf("PL_X_AXIS = %d\n", PL_X_AXIS);
  return 0;
}
|}

(** Flags for compatibility with newer, less permissive versions of
    GCC. *)
let gcc_compat_cflags = ["-Wno-error=incompatible-pointer-types"]

(** [cflag_supported ~c cflag] tests that [cflag] is accepted by the C
    compiler in the Configurator context [c]. *)
let cflag_supported ~c cflag =
  let noop_test = "int main() { return 0; }\n" in
  let result = C.c_test c noop_test ~c_flags:[cflag] ~link_flags:[] in
  if result then Format.eprintf "C compiler accepts flag: %s\n" cflag ;
  result

(** [compat_cflags ~c] detects any relevant compatibility flags
    accepted by the C compiler in the Configurator context [c]. Note
    that with some compiler versions, a flag may specify behavior
    that's enabled by default. *)
let compat_cflags ~c =
  let filter_cflags = List.filter (cflag_supported ~c) in
  match C.ocaml_config_var c "c_compiler" with
  | Some "gcc" -> filter_cflags gcc_compat_cflags
  | _ -> []

let () =
  C.main ~name:"plplot" (fun c ->
      let conf =
        let default = { C.Pkg_config.cflags = []; libs = ["-lplplot"] } in
        match C.Pkg_config.get c with
        | None -> default
        | Some p -> begin
            match C.Pkg_config.query ~package:"plplot" p with
            | None -> begin
                match C.Pkg_config.query ~package:"plplotd" p with 
                | None -> default 
                | Some conf -> conf
              end
            | Some conf -> conf
          end 
      in
      let c_flags = conf.cflags @ compat_cflags ~c in
      if not
        @@ C.c_test
          c
          plplot_test
          ~c_flags
          ~link_flags:conf.libs
      then
        failwith "No valid installation of plplot or plplotd found." ;
      C.Flags.write_sexp "c_flags.sexp" c_flags;
      C.Flags.write_sexp "c_library_flags.sexp" conf.libs)
