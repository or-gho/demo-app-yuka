let read file = In_channel.with_open_bin file In_channel.input_all

let () =
  let dir = "_build/default/client/out" in
  let assets =
    match
      Yuka.Server.modules ~dir ~entry:"client/main.js"
        ~manifest:(read "_build/default/client/yuka_islands.json")
        ~packages:(Array.to_list (Sys.readdir (Filename.concat dir "node_modules")))
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
