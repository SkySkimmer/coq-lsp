(*************************************************************************)
(* Copyright 2015-2019 MINES ParisTech -- Dual License LGPL 2.1+ / GPL3+ *)
(* Copyright 2019-2024 Inria           -- Dual License LGPL 2.1+ / GPL3+ *)
(* Copyright 2024-2025 Emilio J. Gallego Arias  -- LGPL 2.1+ / GPL3+     *)
(* Copyright 2025      CNRS                     -- LGPL 2.1+ / GPL3+     *)
(* Written by: Emilio J. Gallego Arias & coq-lsp contributors            *)
(*************************************************************************)

module Level = struct
  type t =
    | Error
    | Warning
    | Info
    | Log
    | Debug
end

module CallBack = struct
  type t =
    { trace : string -> ?verbose:string -> string -> unit
    ; message : lvl:Level.t -> message:string -> unit
    ; diagnostics :
        uri:Lang.LUri.File.t -> version:int -> Lang.Diagnostic.t list -> unit
    ; fileProgress :
        uri:Lang.LUri.File.t -> version:int -> Progress.Info.t list -> unit
    ; perfData : uri:Lang.LUri.File.t -> version:int -> Perf.t -> unit
    ; serverVersion : ServerInfo.Version.t -> unit
    ; serverStatus : ServerInfo.Status.t -> unit
    }

  let default =
    { trace = (fun _ ?verbose:_ _ -> ())
    ; message = (fun ~lvl:_ ~message:_ -> ())
    ; diagnostics = (fun ~uri:_ ~version:_ _ -> ())
    ; fileProgress = (fun ~uri:_ ~version:_ _ -> ())
    ; perfData = (fun ~uri:_ ~version:_ _ -> ())
    ; serverVersion = (fun _ -> ())
    ; serverStatus = (fun _ -> ())
    }

  let cb = ref default
  let set t = cb := t
end

(** Trace *)
module TraceValue = struct
  type t =
    | Off
    | Messages
    | Verbose

  let of_string = function
    | "messages" -> Ok Messages
    | "verbose" -> Ok Verbose
    | "off" -> Ok Off
    | v -> Error ("TraceValue.parse: " ^ v)

  let to_string = function
    | Off -> "off"
    | Messages -> "messages"
    | Verbose -> "verbose"
end

module Log = struct
  let trace_value = ref TraceValue.Off
  let set_trace_value value = trace_value := value

  let trace_ d ?verbose m =
    match !trace_value with
    | Off -> ()
    | Messages -> !CallBack.cb.trace d ?verbose:None m
    | Verbose -> !CallBack.cb.trace d ?verbose m

  let trace d ?verbose = Format.kasprintf (fun m -> trace_ d ?verbose m)

  let trace_object hdr obj =
    (* Fixme, use the extra parameter *)
    trace hdr "[%s]: @[%a@]" hdr Yojson.Safe.(pretty_print ~std:false) obj

  let pp_fb fmt (fb : Loc.t Coq.Message.t) =
    let _lvl, { Coq.Message.Payload.msg; _ } = fb in
    Format.fprintf fmt "%a" Pp.pp_with msg

  let feedback part feedback =
    if not (CList.is_empty feedback) then
      (* We put the feedback contents in the verbose part of the trace
         message. *)
      let pp_sep = Format.pp_print_cut in
      let feedbacks =
        Format.(asprintf "@[%a@]" (pp_print_list ~pp_sep pp_fb) feedback)
      in
      let verbose = Some feedbacks in
      trace "feedback" ?verbose "received in %s" part
end

module Report = struct
  let message_ ~io ~lvl ~message = io.CallBack.message ~lvl ~message
  let msg ~io ~lvl = Format.kasprintf (fun m -> message_ ~io ~lvl ~message:m)
  let diagnostics ~io ~uri ~version d = io.CallBack.diagnostics ~uri ~version d

  let fileProgress ~io ~uri ~version d =
    io.CallBack.fileProgress ~uri ~version d

  let perfData ~io ~uri ~version pd = io.CallBack.perfData ~uri ~version pd
  let serverVersion ~io vi = io.CallBack.serverVersion vi
  let serverStatus ~io st = io.CallBack.serverStatus st
end
