Router.make ~not_found:Pages.not_found
  [ Router.route Home ~path:"/" ~page:Pages.home ]
