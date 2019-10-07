
module C = Configurator.V1

let write_file f s =
  let out = open_out f in
  output_string out s; flush out; close_out out

let read_file f =
  let in_channel = open_in f in
  let buf = Buffer.create 4096 in
  begin try
    while true; do
      Buffer.add_channel buf in_channel 4096
    done
  with End_of_file -> () end;
  close_in in_channel;
  Buffer.contents buf

let shims_pre_407 = "module Stdlib = Pervasives"

let shims_post_407 = "module Stdlib = Stdlib"

let shims_fmt_pre_408 = "
include Format
let cc_update_funs funs f1 f2 =
  let open Format in
  {
    funs with
    mark_open_tag = f1 funs.mark_open_tag;
    mark_close_tag = f2 funs.mark_close_tag;
  }

"
let shims_fmt_post_408 = "
open Format

[@@@ocaml.warning \"-3\"]

let pp_open_tag = pp_open_tag
let pp_close_tag = pp_close_tag
let pp_get_formatter_tag_functions = pp_get_formatter_tag_functions
let pp_set_formatter_tag_functions = pp_set_formatter_tag_functions

let cc_update_funs funs f1 f2 =
  let open Format in
  {
    funs with
    mark_open_tag = f1 ~or_else:funs.mark_open_tag;
    mark_close_tag = f2 ~or_else:funs.mark_close_tag;
  }
"

let shims_fun_pre_408 =
  read_file "stdlib/fun.ml"
let shims_fun_mli_pre_408 =
  " (** {1:license License} *)

(** This is the [Fun] module distributed with the OCaml Core system.
    It is linked with containers in case the installed OCaml system does not
    provide a compatible [Fun] module.
    It is the an unmodified version of [Fun] as shipped with the OCaml core
    system.
 *)
"
  ^ read_file "stdlib/fun.mli"

let shims_fun_post_408 = "include Fun"
let shims_fun_mli_post_408 = "include module type of Fun"

let shims_list_pre_408 = "
  include List
  type +'a t = 'a list
"
let shims_list_post_408 = "include List"

let shims_array_pre_408 = "
  include Array
  type 'a t = 'a array
"
let shims_array_post_408 = "include Array"

let () =
  C.main ~name:"mkshims" (fun c ->
    let version = C.ocaml_config_var_exn c "version" in
    let major, minor = Scanf.sscanf version "%u.%u" (fun maj min -> maj, min) in
    write_file "CCShims_.ml" (if (major, minor) >= (4,7) then shims_post_407 else shims_pre_407);
    write_file "CCShimsList_.ml" (if (major, minor) >= (4,8) then shims_list_post_408 else shims_list_pre_408);
    write_file "CCShimsArray_.ml" (if (major, minor) >= (4,8) then shims_array_post_408 else shims_array_pre_408);
    write_file "CCShimsFormat_.ml" (if (major, minor) >= (4,8) then shims_fmt_post_408 else shims_fmt_pre_408);
    write_file "CCShimsFun_.ml" (if (major, minor) >= (4,8) then shims_fun_post_408 else shims_fun_pre_408);
    write_file "CCShimsFun_.mli" (if (major, minor) >= (4,8) then shims_fun_mli_post_408 else shims_fun_mli_pre_408);
  )
