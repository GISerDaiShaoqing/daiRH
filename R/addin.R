# DaiRH Addin \u5165\u53E3 ------------------------------------------------------------
# \u6CE8\u518C\u6587\u4EF6\uFF1Ainst/rstudio/addins.dcf
#   - DaiRH Chat    -> dairh_addin_chat()
#   - DaiRH Settings -> dairh_addin_settings()

#' \u6253\u5F00 DaiRH \u804A\u5929\u52A9\u624B\u9762\u677F\uFF08RStudio Addin\uFF09
#'
#' \u5728 RStudio \u7684 Viewer \u9762\u677F\u4E2D\u6253\u5F00\u5BF9\u8BDD\u5F0F Agent\u3002\u963B\u585E\u65B9\u5F0F\u8FD0\u884C\uFF1A
#' \u4E0E\u9762\u677F\u4EA4\u4E92\u65F6\u63A7\u5236\u53F0\u5904\u4E8E\u5FD9\u788C\u72B6\u6001\u5C5E\u6B63\u5E38\u73B0\u8C61\u3002
#'
#' @examples
#' \dontrun{
#' dairh_addin_chat()
#' }
#' @export
dairh_addin_chat <- function() {
  cfg <- dairh_config_get()
  if (identical(.dairh_norm_run_mode(cfg$run_mode), "bg")) {
    return(.dairh_chat_launch_bg(cfg))
  }
  app <- dairh_app(cfg)
  tryCatch(
    shiny::runGadget(
      app$ui, app$server,
      viewer = shiny::paneViewer(minHeight = 500),
      stopOnCancel = TRUE
    ),
    error = function(e) {
      msg <- conditionMessage(e)
      if (!grepl("cancelled|shiny_gadget_stopped|Gadget", msg, ignore.case = TRUE)) {
        stop(e)
      }
      invisible()
    }
  )
  invisible()
}

#' \u6253\u5F00 DaiRH \u8BBE\u7F6E\u5BF9\u8BDD\u6846\uFF08RStudio Addin\uFF09
#'
#' @examples
#' \dontrun{
#' dairh_addin_settings()
#' }
#' @export
dairh_addin_settings <- function() {
  cfg <- dairh_config_get()
  ui <- dairh_settings_page_ui(cfg)
  server <- function(input, output, session) {
    dairh_settings_observers(input, output, session, cfg, standalone = TRUE)
  }
  tryCatch(
    shiny::runGadget(
      ui, server,
      viewer = shiny::dialogViewer("DaiRH \u8BBE\u7F6E", width = 560, height = 700),
      stopOnCancel = TRUE
    ),
    error = function(e) {
      msg <- conditionMessage(e)
      if (!grepl("cancelled|shiny_gadget_stopped|Gadget", msg, ignore.case = TRUE)) {
        stop(e)
      }
      invisible()
    }
  )
  invisible()
}
