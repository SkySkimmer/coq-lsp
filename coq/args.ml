(************************************************************************)
(* Flèche => document manager: Document                                 *)
(* Copyright 2019 MINES ParisTech -- Dual License LGPL 2.1 / GPL3+      *)
(* Copyright 2019-2024 Inria      -- Dual License LGPL 2.1 / GPL3+      *)
(* Written by: Emilio J. Gallego Arias & coq-lsp contributors           *)
(************************************************************************)

open Cmdliner

(****************************************************************************)
(* Common Coq command-line arguments *)
let coqlib =
  let doc =
    "Load Coq.Init.Prelude from $(docv); theories and user-contrib should live \
     there."
  in
  Arg.(
    value & opt string Coq_config.coqlib & info [ "coqlib" ] ~docv:"COQLIB" ~doc)

let coqcorelib =
  let doc = "Path to Coq plugin directories." in
  Arg.(
    value
    & opt string (Filename.concat Coq_config.coqlib "../rocq-runtime/")
    & info [ "rocqcorelib" ] ~docv:"COQCORELIB" ~doc)

let findlib_config =
  let doc = "Override findlib's config file" in
  Arg.(
    value
    & opt (some string) None
    & info [ "findlib_config" ] ~docv:"OCAMLFIND_CONF" ~doc)

let ocamlpath =
  let doc = "Extra Paths to OCaml's libraries" in
  Arg.(
    value & opt (list string) [] & info [ "ocamlpath" ] ~docv:"OCAMLPATH" ~doc)

let coq_lp_conv ~implicit (unix_path, lp) =
  { Loadpath.coq_path = Libnames.dirpath_of_string lp
  ; unix_path
  ; implicit
  ; recursive = true
  }

let rload_paths : Loadpath.vo_path list Term.t =
  let doc =
    "Bind a logical loadpath LP to a directory DIR and implicitly open its \
     namespace."
  in
  Term.(
    const List.(map (coq_lp_conv ~implicit:true))
    $ Arg.(
        value
        & opt_all (pair dir string) []
        & info [ "R"; "rec-load-path" ] ~docv:"DIR,LP" ~doc))

let qload_paths : Loadpath.vo_path list Term.t =
  let doc = "Bind a logical loadpath LP to a directory DIR" in
  Term.(
    const List.(map (coq_lp_conv ~implicit:false))
    $ Arg.(
        value
        & opt_all (pair dir string) []
        & info [ "Q"; "load-path" ] ~docv:"DIR,LP" ~doc))

let debug : bool Term.t =
  let doc = "Enable debug mode" in
  Arg.(value & flag & info [ "debug" ] ~doc)

let bt =
  let doc = "Enable backtraces" in
  Cmdliner.Arg.(value & flag & info [ "bt" ] ~doc)

let ml_include_path : string list Term.t =
  let doc = "Include DIR in default loadpath, for locating ML files" in
  Arg.(
    value & opt_all dir [] & info [ "I"; "ml-include-path" ] ~docv:"DIR" ~doc)

let ri_from : (string option * string) list Term.t =
  let doc =
    "FROM Require Import LIBRARY before creating the document, à la From Coq \
     Require Import Prelude"
  in
  Term.(
    const (List.map (fun (x, y) -> (Some x, y)))
    $ Arg.(
        value
        & opt_all (pair string string) []
        & info [ "rifrom"; "require-import-from" ] ~docv:"FROM,LIBRARY" ~doc))

let int_backend =
  let docv = "BACKEND" in
  let backends = [ ("Coq", Limits.Coq); ("Mp", Limits.Mp) ] in
  let backends_str =
    "either 'Mp', for memprof-limits token-based interruption,\n\
    \  or 'Coq', for Coq's polling mode (unreliable). The 'Mp' backend is only \
     supported in OCaml 4.x series."
  in
  let doc =
    Printf.sprintf
      "Select Interruption Backend, if absent, the best available for your \
       OCaml version will be selected. %s is %s"
      docv backends_str
  in
  let absent = "'Mp' for OCaml 4.x, 'Coq' for OCaml 5.x" in
  Arg.(
    value
    & opt (some (enum backends)) None
    & info [ "int_backend" ] ~docv ~doc ~absent)

let roots : string list Term.t =
  let doc = "Workspace(s) root(s)" in
  Arg.(value & opt_all string [] & info [ "root" ] ~docv:"ROOTS" ~doc)

let coq_diags_level : int Term.t =
  let doc =
    "Controls whether Coq Info and Notice message appear in diagnostics.\n\
    \ 0 = None; 1 = Notices, 2 = Notices and Info"
  in
  Arg.(value & opt int 0 & info [ "diags_level" ] ~docv:"DIAGS_LEVEL" ~doc)
