# testShinyExamples::set_public("barret", "beta.rstudioconnect.com", "APIKEY")


#' Make Connect Shiny applications publically available
#'
#' To not have to provide the key, the \code{rsconnect} account should already exist.  This can be done by calling \code{rsconnect::connectApiUser} to add the appropriate account information.
#'
#' @inheritParams deploy_apps
#' @param api_key API key generated from the connect server.
#' @rdname connect_set_public
#' @export
#' @examples
#' \dontrun{
#'   connect_set_public(account = "barret", server = "beta.rstudioconnect.com")
#' }
connect_set_public <- function(
  dir = "apps",
  apps = basename(apps_deploy(dir)),
  account = "barret",
  server = "beta.rstudioconnect.com"
) {

  # apps_dirs <- file.path(dir, apps)
  apps_dir_names <- basename(apps)

  acct_info <- validate_rsconnect_account(account, server)
  api_key <- acct_info$apiKey
  api_get <- api_get_(server, api_key)
  api_post <- api_post_(server, api_key)

  apps_info <- api_get(paste0("/applications?count=1000&filter=account_id:", acct_info$accountId))
  apps <- subset_and_order_apps(apps_info$applications, apps_dir_names)

  pb <- progress::progress_bar$new(
    total = length(apps),
    format = "[:bar] :current/:total eta::eta :app\n",
    show_after = 0,
    clear = FALSE
  )
  lapply(
    apps,
    function(app) {
      pb$tick(tokens = list(app = app$name))
      api_post(
        paste0("/applications/", app$id),
        list(
          id = app$id,
          access_type = "all"
        )
      )
    }
  )

  app_names <- vapply(apps, `[[`, character(1), "name")
  # ask for applications using the deployed app name
  app_urls <- connect_urls(dir = "", apps = app_names, account = account, server = server)

  returns <- rep("\n", length(app_urls))
  if (length(app_urls) > 10) {
    returns[seq(from = 10, to = length(app_urls), by = 10)] <- "\n\n\n"
  }

  cat(
    "\nApplications deployed: \n",
    paste0(format(names(app_urls), justify = "left"), " - ", unname(app_urls), returns, collapse = ""),
    "\n",
    sep = ""
  )

  invisible(app_urls)
}

#' @rdname connect_set_public
#' @export
connect_urls <- function(
  dir = "apps",
  apps = basename(apps_deploy(dir)),
  account = "barret",
  server = "beta.rstudioconnect.com"
) {
  # apps_dirs <- file.path(dir, apps)
  apps_dir_names <- basename(apps)

  acct_info <- rsconnect::accountInfo(account, server)
  api_get <- api_get_(server, acct_info$apiKey)
  api_post <- api_post_(server, acct_info$apiKey)

  apps_info <- api_get(paste0("/applications?count=1000&filter=account_id:", acct_info$accountId))

  apps <- subset_and_order_apps(apps_info$applications, apps_dir_names)

  app_urls <- vapply(apps, `[[`, character(1), "url")
  names(app_urls) <- vapply(apps, `[[`, character(1), "name")

  app_urls
}


api_get_ <- function(server, api_key) {
  server_url <- rsconnect::serverInfo(server)$url
  function(route) {
    req <- httr::GET(
      paste0(server_url, route),
      httr::content_type_json(),
      httr::add_headers(
        Authorization = paste0("Key ", api_key)
      )
    )
    httr::content(req, as = "parsed")
  }
}
api_post_ <- function(server, api_key) {
  server_url <- rsconnect::serverInfo(server)$url
  function(route, body) {
    req <- httr::POST(
      paste0(server_url, route),
      body = body,
      encode = "json",
      httr::add_headers(
        Authorization = paste0("Key ", api_key)
      )
    )
    httr::content(req, as = "parsed")
  }
}


subset_and_order_apps <- function(appInfos, final_names) {

  # order the urls
  apps_names <- vapply(appInfos, `[[`, character(1), "name")
  # get only final_names that exist in app set
  final_names_that_exist <- final_names[final_names %in% apps_names]
  # created a named vector to leverage R's named vector subsetting
  positions <- setNames(seq(length(appInfos)), apps_names)
  # use the final names to get the order
  final_pos <- positions[final_names_that_exist]

  appInfos[final_pos]
}
