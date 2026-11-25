let read file = In_channel.with_open_bin file In_channel.input_all

let rec mkdir_p dir =
  if not (Sys.file_exists dir) then begin
    mkdir_p (Filename.dirname dir);
    Unix.mkdir dir 0o755
  end

let extract_assets () =
  let tmp_dir = Filename.temp_file "yuka_assets" "" in
  Sys.remove tmp_dir;
  Unix.mkdir tmp_dir 0o755;
  List.iter (fun path ->
    match Yuka_assets.read path with
    | Some content ->
      let dest = Filename.concat tmp_dir path in
      mkdir_p (Filename.dirname dest);
      Out_channel.with_open_bin dest (fun oc -> Out_channel.output_string oc content)
    | None -> ()
  ) Yuka_assets.file_list;
  tmp_dir

let manifest_json = {|{"App_shared.Counter":"../shared/counter.js"}|} 
let () =
  let dir = extract_assets () in
  let assets =
    match
      Yuka.Server.modules ~dir ~entry:"client/main.js"
        ~manifest: manifest_json
        ~packages:(try Array.to_list (Sys.readdir (Filename.concat dir "node_modules")) with _ -> [])
        ~digest:(Yuka.Server.tree_digest dir)
    with
    | Ok assets -> assets
    | Error message ->
        prerr_endline message;
        exit 1
  in
  let config =
    Yuka.Server.config ~assets ~css:Yuka_css.sheets
      ~dev:(Sys.getenv_opt "YUKA_DEV" = Some "1")
      ()
  in
  Dream.run @@ Dream.logger @@ Dream.set_secret "change-me"
  @@ Dream.cookie_sessions
  @@ Yuka_dream.handler config Yuka_routes.app
