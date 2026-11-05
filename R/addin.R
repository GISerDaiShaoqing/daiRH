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

#' \u628A\u9009\u4E2D\u7684\u4EE3\u7801\u4E00\u952E\u53D1\u9001\u5230 DaiRH \u9762\u677F\uFF08RStudio Addin\uFF09
#'
#' \u5728\u4E3B\u4F1A\u8BDD\u5185\u76F4\u63A5\u8BFB\u53D6\u6E90\u7801\u7F16\u8F91\u5668\u7684\u5F53\u524D\u9009\u533A\uFF08\u4E0D\u8D70\u5FEB\u7167\u3001\u4E0D\u4F9D\u8D56\u63A7\u5236\u53F0\u6D3B\u52A8\uFF09\uFF0C
#' \u7EC4\u88C5\u8BB2\u89E3\u63D0\u793A\u8BCD\u540E\u7ECF\u6865\u901A\u9053\u76F4\u53D1\uFF0C\u540E\u53F0\u9762\u677F\u4F1A\u5728\u7EA6\u534A\u79D2\u5185\u81EA\u52A8\u63D0\u4EA4\u7ED9\u6A21\u578B\u3002
#' \u63A8\u8350\u5728 Tools \u2192 Modify Keyboard Shortcuts \u91CC\u7ED9\u672C\u52A0\u8F7D\u9879\u7ED1\u4E00\u4E2A\u5FEB\u6377\u952E\uFF0C
#' \u4E4B\u540E"\u9009\u4E2D\u4EE3\u7801 \u2192 \u6309\u5FEB\u6377\u952E"\u5373\u53EF\u3002
#'
#' @examples
#' \dontrun{
#' dairh_addin_send_selection()
#' }
#' @export
dairh_addin_send_selection <- function() {
  if (!.dairh_rstudio_available()) {
    message("daiRH: \u4E0D\u5728 RStudio \u4E2D\uFF0C\u65E0\u6CD5\u8BFB\u53D6\u7F16\u8F91\u5668\u9009\u533A\u3002")
    return(invisible())
  }
  ctx <- tryCatch(rstudioapi::getSourceEditorContext(), error = function(e) NULL)
  sel <- if (!is.null(ctx)) {
    tryCatch(rstudioapi::primary_selection(ctx), error = function(e) NULL)
  } else NULL
  txt <- sel$text
  if (is.null(txt) || !nzchar(trimws(txt))) {
    message("daiRH: \u8BF7\u5148\u5728\u7F16\u8F91\u5668\u91CC\u9009\u4E2D\u8981\u8BB2\u89E3\u7684\u4EE3\u7801\uFF0C\u518D\u8FD0\u884C\u672C\u52A0\u8F7D\u9879\u3002")
    return(invisible())
  }
  path_lab <- if (nzchar(ctx$path %||% "")) ctx$path else
    "\uFF08\u672A\u4FDD\u5B58\u7684\u65E0\u6807\u9898\u6587\u6863\uFF09"
  s <- .dairh_pos_row(sel$range$start, 1L)
  e <- .dairh_pos_row(sel$range$end, s)
  prompt <- paste0(
    "\u8BF7\u8BB2\u89E3\u6211\u5728 RStudio \u91CC\u9009\u4E2D\u7684\u8FD9\u6BB5\u4EE3\u7801\uFF08", path_lab, " \u7B2C ", s, "\u2013", e, " \u884C\uFF09\uFF1A\n\n",
    "```r\n", txt, "\n```\n\n",
    "\u8BB2\u6E05\u5B83\u505A\u4EC0\u4E48\u3001\u8FD4\u56DE\u4EC0\u4E48\u3001\u5728\u4E0A\u4E0B\u6587\u4E2D\u7684\u4F5C\u7528\uFF1B\u5982\u6709\u9690\u60A3\u8BF7\u987A\u5E26\u6307\u51FA\u3002\u5168\u7A0B\u4E2D\u6587\uFF0C\u4EE3\u7801\u4FDD\u7559\u82F1\u6587\u3002"
  )
  # \u987A\u624B\u628A\u5FEB\u7167\u5237\u6210\u6B64\u523B\u7684\u771F\u72B6\u6001\uFF08\u540E\u7EED\u89E3\u91CA\u5F53\u524D\u6587\u4EF6/\u5BA1\u67E5\u7B49\u6309\u94AE\u540C\u6837\u53D7\u76CA\uFF09
  .dairh_write_context_snapshot()
  .dairh_pending_prompt_write(prompt)
  message("daiRH: \u9009\u533A\u5DF2\u53D1\u9001\uFF0C\u540E\u53F0\u9762\u677F\u5C06\u5728\u7EA6\u534A\u79D2\u5185\u81EA\u52A8\u63D0\u4EA4\u3002")
  invisible()
}
