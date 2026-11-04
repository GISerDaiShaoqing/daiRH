# RStudio \u4E0A\u4E0B\u6587\u96C6\u6210 ----------------------------------------------------------

.dairh_rstudio_available <- function() {
  requireNamespace("rstudioapi", quietly = TRUE) && rstudioapi::isAvailable()
}

#' \u5F53\u524D\u57FA\u7840\u76EE\u5F55\uFF08\u5B89\u5168\u8FB9\u754C\uFF09
#'
#' RStudio \u4E2D\u5E26 .Rproj \u6253\u5F00\u65F6\u7528\u9879\u76EE\u76EE\u5F55\uFF0C\u5426\u5219\u7528 getwd()\u3002
#' \u6587\u4EF6\u7C7B\u5DE5\u5177\u9ED8\u8BA4\u9650\u5236\u5728\u6B64\u76EE\u5F55\u5185\u3002
dairh_base_dir <- function() {
  proj <- tryCatch(rstudioapi::getActiveProject(), error = function(e) NULL)
  if (is.null(proj) || !nzchar(proj)) getwd() else proj
}

#' \u5F53\u524D\u6253\u5F00\u6587\u4EF6 / \u9009\u533A\u4E0A\u4E0B\u6587\uFF08\u6587\u672C\uFF09
#'
#' \u751F\u6210\u7ED9 LLM \u770B\u7684\u4E0A\u4E0B\u6587\u6458\u8981\uFF1A\u6587\u4EF6\u8DEF\u5F84\u4E0E\u5185\u5BB9\uFF08\u622A\u65AD\uFF09\u3001\u9009\u533A\u6587\u672C\u4E0E\u884C\u53F7\u3002
#' \u4E0D\u5728 RStudio \u4E2D\u65F6\u8FD4\u56DE\u63D0\u793A\u6587\u672C\u3002
#'
#' @param max_lines \u6587\u4EF6\u5185\u5BB9\u6700\u591A\u6CE8\u5165\u7684\u884C\u6570
#' @return \u5355\u4E2A\u5B57\u7B26\u4E32\uFF08markdown/\u7EAF\u6587\u672C\u5757\uFF09
#' @export
dairh_editor_context_text <- function(max_lines = 160) {
  if (!.dairh_rstudio_available()) {
    return("\u5F53\u524D\u4E0D\u5728 RStudio \u4E2D\uFF0C\u65E0\u6CD5\u8BFB\u53D6\u6D3B\u52A8\u7F16\u8F91\u5668\u4E0A\u4E0B\u6587\u3002")
  }
  ctx <- tryCatch(rstudioapi::getActiveDocumentContext(), error = function(e) NULL)
  if (is.null(ctx) || !nzchar(ctx$path %||% "")) {
    return("\u5F53\u524D\u6CA1\u6709\u5904\u4E8E\u4FDD\u5B58\u72B6\u6001\u7684\u6587\u4EF6\u53EF\u4F9B\u8BFB\u53D6\u3002\u8BF7\u5148\u4FDD\u5B58\u6587\u4EF6\uFF0C\u6216\u544A\u8BC9\u6211\u6587\u4EF6\u8DEF\u5F84\u3002")
  }
  path <- ctx$path
  lines <- strsplit(ctx$contents %||% "", "\n", fixed = TRUE)[[1]] %||% character(0)
  n <- length(lines)
  show_n <- min(n, max_lines)
  out <- c(
    sprintf("\u3010\u6D3B\u52A8\u6587\u4EF6\u3011%s\uFF08\u5171 %d \u884C\uFF09", path, n),
    "\u5185\u5BB9\uFF1A",
    .dai_numbered(lines[seq_len(show_n)], 1L)
  )
  if (show_n < n) out <- c(out, sprintf("...\uFF08\u5171 %d \u884C\uFF0C\u4EC5\u663E\u793A\u524D %d \u884C\uFF0C\u53EF\u7528 read_file \u7EE7\u7EED\u8BFB\u53D6\u5176\u4F59\u90E8\u5206\uFF09", n, max_lines))

  sel <- tryCatch(rstudioapi::primary_selection(ctx), error = function(e) NULL)
  if (!is.null(sel) && !is.null(sel$text) && nzchar(sel$text)) {
    s <- sel$range$start$rE
    out <- c(
      out,
      sprintf("\u3010\u5F53\u524D\u9009\u533A\u3011\u7B2C %d\u2013%d \u884C\uFF1A", s, sel$range$end$rE),
      .dai_numbered(strsplit(sel$text, "\n", fixed = TRUE)[[1]], s)
    )
  }
  paste0(c(out, ""), collapse = "\n")
}

# \u7F16\u8F91\u540E\u8DF3\u8F6C\u5230\u5BF9\u5E94\u884C\uFF08\u5C3D\u529B\u800C\u4E3A\uFF0C\u4E0D\u5728 RStudio \u6216\u5931\u8D25\u65F6\u9759\u9ED8\u8DF3\u8FC7\uFF09
# \u540E\u53F0\u6A21\u5F0F\uFF1A\u4F18\u5148\u628A\u8DF3\u8F6C\u8BF7\u6C42\u53D1\u7ED9\u4E3B\u4F1A\u8BDD\u5185\u7684\u80FD\u529B\u6865
dairh_nav <- function(path, line = 1) {
  br <- tryCatch(
    .dairh_bridge_get("/nav", list(path = path, line = as.integer(line))),
    error = function(e) character(0)
  )
  if (length(br) && nzchar(br)) return(invisible(identical(br, "ok")))
  if (!.dairh_rstudio_available()) return(invisible(FALSE))
  tryCatch(
    {
      rstudioapi::navigateToFile(path, line = as.integer(line))
      invisible(TRUE)
    },
    error = function(e) invisible(FALSE)
  )
}
