# testShinyExamples::set_public("barret", "beta.rstudioconnect.com", "APIKEY")


#' Make Connect Shiny applications publically available
#'
#' The corresponding \code{rsconnect} account should already exist before calling \code{connect_set_public}.  This can be done by calling \code{rsconnect::connectApiUser} to add the appropriate account information.
#'
#' @inheritParams deploy_apps
#' @describeIn connect Set all the Shiny apps to be public on a Connect server
#' @export
#' @examples
#' \dontrun{
#'   rsconnect::addConnectServer(url = 'https://SERVER.com/API', name = 'CustomName')"
#'   rsconnect::connectApiUser('barret', 'CustomName', apiKey = 'SuperSecretKey')"
#'   deploy_apps(account = 'barret', server = 'CustomName')"
#'   connect_set_public(account = 'barret', server = 'CustomName')"
#'   urls <- connect_urls(account = 'barret', server = 'CustomName')
#' }
connect_set_public <- function(
  apps = apps_shiny,
  account = "barret",
  server = "beta.rstudioconnect.com"
) {
  apps <- vapply(apps, resolve_app_name, character(1))
  stopifnot(is.character(apps))

  acct_info <- validate_rsconnect_account(account, server)
  api_key <- acct_info$apiKey
  api_get <- api_get_(server, api_key)
  api_post <- api_post_(server, api_key)

  apps_info <- api_get(paste0("/applications?count=1000&filter=account_id:", acct_info$accountId))
  apps <- subset_and_order_apps(apps_info$applications, apps)

  pb <- progress_bar(
    total = length(apps),
    format = "[:bar] :current/:total eta::eta :app\n"
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
  app_urls <- connect_urls(apps = app_names, account = account, server = server)

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

#' @describeIn connect Retrieve the urls from a Connect server using the Shiny applications provided in \verb{dir}
#' @export
connect_urls <- function(
  apps = apps_shiny,
  account = "barret",
  server = "beta.rstudioconnect.com"
) {
  check_installed("rsconnect")

  # apps_dirs <- file.path(dir, apps)
  stopifnot(is.character(apps))
  app_names <- vapply(apps, resolve_app_name, character(1))

  acct_info <- rsconnect::accountInfo(account, server)
  api_get <- api_get_(server, acct_info$apiKey)
  api_post <- api_post_(server, acct_info$apiKey)

  apps_info <- api_get(paste0("/applications?count=1000&filter=account_id:", acct_info$accountId))

  apps <- subset_and_order_apps(apps_info$applications, app_names)

  app_urls <- vapply(apps, `[[`, character(1), "url")
  names(app_urls) <- vapply(apps, `[[`, character(1), "name")

  attr(app_urls, "account") <- account
  attr(app_urls, "server") <- server

  app_urls
}


api_get_ <- function(server, api_key) {
  check_installed("rsconnect")

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
  check_installed("rsconnect")

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

#' @importFrom stats setNames
subset_and_order_apps <- function(app_infos, final_names) {

  # order the urls
  apps_names <- vapply(app_infos, `[[`, character(1), "name")
  # get only final_names that exist in app set
  final_names_that_exist <- final_names[final_names %in% apps_names]
  # created a named vector to leverage R's named vector subsetting
  positions <- setNames(seq(length(app_infos)), apps_names)
  # use the final names to get the order
  final_pos <- positions[final_names_that_exist]

  app_infos[final_pos]
}
