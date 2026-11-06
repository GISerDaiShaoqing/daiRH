# DaiRH Harness \u6838\u5FC3 -------------------------------------------------------------
# \u8BA9 daiRH \u6210\u4E3A\u771F\u6B63\u7684 harness\uFF1A
#   1. \u5DE5\u5177\u6CE8\u518C\u8868\uFF08\u5185\u7F6E 8 \u5DE5\u5177 + \u7528\u6237 dairh_register_tool() \u6CE8\u518C\u7684\u81EA\u5B9A\u4E49\u5DE5\u5177\uFF09
#   2. \u94A9\u5B50\u7CFB\u7EDF\uFF08pre_tool \u62E6\u622A / post_tool \u6539\u5199\uFF09
#   3. \u5355\u8F6E\u786C\u6B65\u6570\u9884\u7B97\uFF08\u8D85\u51FA\u5373\u62E6\u622A\uFF0C\u65B0\u7528\u6237\u6D88\u606F\u81EA\u52A8\u91CD\u7F6E\uFF09
#   4. \u8C03\u7528\u8F68\u8FF9 trace\uFF08jsonl\uFF0C\u53EF\u56DE\u653E\u6BCF\u4E00\u6B65\u5DE5\u5177\u8C03\u7528\uFF09
# \u67B6\u6784\u8BF4\u660E\uFF1A\u540E\u53F0\u6A21\u5F0F\u4E0B\u9762\u677F\u8DD1\u5728 callr \u5B50\u8FDB\u7A0B\uFF0C\u4E3B\u4F1A\u8BDD\u91CC\u6CE8\u518C\u7684\u5DE5\u5177/\u94A9\u5B50
# \u5BF9\u5B50\u8FDB\u7A0B\u4E0D\u53EF\u89C1\uFF1B\u81EA\u5B9A\u4E49\u5185\u5BB9\u8BF7\u5199\u8FDB cfg$tools_profile \u811A\u672C\uFF0C\u9762\u677F\u542F\u52A8\u65F6\u4F1A\u81EA\u52A8 source\u3002

# \u5185\u7F6E\u5DE5\u5177\u540D\u5355\uFF08\u4E0E tools_agent.R \u7684\u6784\u5EFA\u4FDD\u6301\u540C\u6B65\uFF09
.dairh_builtin_tools <- function() {
  c(
    "read_file", "list_files", "create_file", "edit_file",
    "run_r_code", "get_r_help", "workspace_summary", "get_editor_context",
    "show_plot", "show_html", "read_skill", "delegate_task"
  )
}

# \u5168\u5C40 harness \u72B6\u6001\uFF08\u6CBF\u7528 background.R \u7684 env \u6A21\u5F0F\uFF1B\u6BCF\u4E2A R \u8FDB\u7A0B\u72EC\u7ACB\u4E00\u4EFD\uFF09
.dairh_harness_env <- new.env(parent = emptyenv())
.dairh_harness_env$tools <- list()   # \u6CE8\u518C\u8868\uFF1aname -> list(fn, description, arguments)
.dairh_harness_env$hooks <- list(pre_tool = list(), post_tool = list())
.dairh_harness_env$profiles <- list()  # \u5DF2 source \u7684 tools_profile\uFF1apath -> mtime \u5B57\u7B26\u4E32
.dairh_harness_env$last_trace <- NULL  # \u6700\u8FD1\u4E00\u4E2A agent \u7684 trace \u6587\u4EF6\u8DEF\u5F84

# ---- \u6BCF\u4E2A agent \u7684\u4F1A\u8BDD\u72B6\u6001 -------------------------------------------------------

.dairh_new_state <- function(cfg = dairh_config_get()) {
  b <- suppressWarnings(as.integer(cfg$max_steps %||% 12L))
  if (length(b) != 1L || is.na(b) || b < 1L) b <- 12L
  st <- new.env(parent = emptyenv())
  st$budget <- b            # \u5355\u8F6E\u786C\u9884\u7B97\uFF08\u6765\u81EA max_steps\uFF09
  st$n_calls <- 0L          # \u672C\u8F6E\u5DF2\u53D1\u751F\u7684\u5DE5\u5177\u8C03\u7528\u6570
  st$last_user_n <- NA_integer_  # \u4E0A\u6B21\u8C03\u7528\u65F6\u770B\u5230\u7684 user \u56DE\u5408\u6570
  st$client <- NULL         # dairh_new_agent \u6CE8\u5165\uFF0C\u56DE\u5408\u68C0\u6D4B\u7528
  st$tag <- "main"          # \u4EE3\u7406\u5C42\u7EA7\uFF08main/sub\uFF0C\u5B50\u4EE3\u7406\u59D4\u6D3E\u65F6\u7F6E sub\uFF09
  st$trace <- isTRUE(cfg$trace)
  st$trace_file <- NULL
  st
}

# ---- trace ------------------------------------------------------------------

.dairh_trace_dir <- function() {
  d <- getOption("daiRH.trace_dir")
  if (is.null(d) || !is.character(d) || !nzchar(d)) {
    # 0.5 \u8D77\u652F\u6301 config.json \u7684 trace_dir\uFF08\u7559\u7A7A = \u9ED8\u8BA4 cache \u76EE\u5F55\uFF09\uFF1Boption \u4F9B\u6D4B\u8BD5\u8986\u76D6
    d <- tryCatch(trimws(dairh_config_get()$trace_dir %||% ""), error = function(e) "")
    if (!is.character(d) || !nzchar(d)) {
      d <- file.path(tools::R_user_dir("daiRH", "cache"), "traces")
    }
  }
  dir.create(d, recursive = TRUE, showWarnings = FALSE)
  d
}

.dairh_trace_write <- function(state, fields) {
  if (!isTRUE(state$trace)) return(invisible(FALSE))
  if (is.null(state$trace_file)) {
    state$trace_file <- file.path(
      .dairh_trace_dir(),
      sprintf("trace-%s-%d.jsonl", format(Sys.time(), "%Y%m%d-%H%M%S"), Sys.getpid())
    )
    .dairh_harness_env$last_trace <- state$trace_file
  }
  line <- tryCatch(
    jsonlite::toJSON(fields, auto_unbox = TRUE, null = "null"),
    error = function(e) NULL
  )
  if (is.null(line) || !is.character(line) || !length(line)) return(invisible(FALSE))
  # \u4E8C\u8FDB\u5236\u8FFD\u52A0\u5199\u5165\uFF1A\u907F\u5F00\u672C\u673A ASCII locale \u4E0B writeLines \u7684\u7F16\u7801\u8F6C\u6362\u5751
  con <- file(state$trace_file, open = "ab")
  on.exit(close(con), add = TRUE)
  writeBin(charToRaw(paste0(enc2utf8(line), "\n")), con)
  invisible(TRUE)
}

#' \u5F53\u524D/\u6700\u8FD1\u4E00\u4E2A Agent \u7684 trace \u6587\u4EF6\u8DEF\u5F84
#'
#' \u8FD4\u56DE\u672C\u8FDB\u7A0B\u6700\u8FD1\u4E00\u6B21\u5199\u5165\u7684 trace jsonl \u6587\u4EF6\u8DEF\u5F84\uFF1B
#' \u82E5\u672C\u8FDB\u7A0B\u8FD8\u6CA1\u5199\u8FC7\uFF0C\u56DE\u9000\u5230 trace \u76EE\u5F55\u91CC\u6700\u65B0\u7684\u4E00\u4E2A\u6587\u4EF6\u3002
#' @return \u6587\u4EF6\u8DEF\u5F84\u5B57\u7B26\u4E32\uFF0C\u6CA1\u6709\u5219 NULL
#' @export
dairh_trace_path <- function() {
  d <- .dairh_trace_dir()
  fs <- list.files(d, pattern = "^trace-.*\\.jsonl$", full.names = TRUE)
  newest <- NULL
  if (length(fs)) {
    info <- file.info(fs)
    newest <- rownames(info)[order(info$mtime, decreasing = TRUE)][[1]]
  }
  # \u7F13\u5B58\u6587\u4EF6\u4E0D\u518D\u4E00\u7968\u5426\u51B3\uFF1A\u591A\u9762\u677F/\u91CD\u5F00\u9762\u677F\u65F6\u76EE\u5F55\u91CC\u4F1A\u51FA\u73B0\u66F4\u65B0\u7684 trace \u6587\u4EF6\uFF0C
  # \u82E5\u7F13\u5B58\u7684\u6BD4\u6700\u65B0\u8FD8\u65E7\u5C31\u8DDF\u968F\u6700\u65B0\uFF08\u5426\u5219\u4E3B\u4F1A\u8BDD\u91CC\u7684 dairh_trace() \u4F1A\u795E\u79D8\u5730
  # \u505C\u5728\u65E7\u8FDB\u7A0B\u7684\u6587\u4EF6\u4E0A\u2014\u20140.5 \u5B9E\u6D4B\u8E29\u8FC7\uFF09\u3002
  p <- .dairh_harness_env$last_trace
  if (!is.null(p) && file.exists(p) && !is.null(newest) && !identical(newest, p)) {
    pn <- file.info(p)$mtime
    nn <- file.info(newest)$mtime
    if (isTRUE(nn > pn)) p <- newest
  } else if (is.null(p) || !file.exists(p)) {
    p <- newest
  }
  .dairh_harness_env$last_trace <- p
  p
}

#' \u67E5\u770B\u6700\u8FD1\u7684\u5DE5\u5177\u8C03\u7528\u8F68\u8FF9
#'
#' \u8BFB\u53D6\u6700\u8FD1\u4E00\u4E2A agent \u7684 trace jsonl \u5C3E\u90E8\uFF0C\u8FD4\u56DE data.frame\u3002
#' \u6BCF\u6B21\u5DE5\u5177\u8C03\u7528\uFF08\u542B\u53C2\u6570\u3001\u8017\u65F6\u3001\u7ED3\u679C\u6458\u8981\u3001\u662F\u5426\u88AB\u62E6\u622A\uFF09\u90FD\u4F1A\u7559\u75D5\u3002
#'
#' @param n \u53D6\u6700\u540E n \u6761\u8BB0\u5F55
#' @return data.frame\uFF08ts / type / tool / duration_s / ok / result / veto ... \u6309\u884C\u4E3A\u4E00\u6B21\u4E8B\u4EF6\uFF09
#' @export
dairh_trace <- function(n = 20) {
  n <- max(1L, as.integer(n)[[1]])
  p <- dairh_trace_path()
  if (is.null(p)) {
    message("\u8FD8\u6CA1\u6709\u4EFB\u4F55 trace \u8BB0\u5F55\uFF08trace \u76EE\u5F55\uFF1A", .dairh_trace_dir(), "\uFF09\u3002")
    return(invisible(NULL))
  }
  # \u5B57\u8282\u7EA7\u8BFB\u53D6 + UTF-8 \u6807\u8BB0\uFF1A\u672C\u673A ASCII locale \u4E0B readLines(encoding=) \u4E0E
  # fromJSON \u7684\u6587\u4EF6\u540D\u542F\u53D1\u5F0F\u90FD\u4F1A\u628A\u542B\u4E2D\u6587\u7684\u957F\u884C\u5F04\u574F\uFF08\u5B9E\u6D4B\u8E29\u8FC7\uFF09\u3002
  raw <- readBin(p, "raw", file.info(p)$size)
  raw <- raw[raw != as.raw(0)]  # \u8003\u7248\u672C writer \u5728 C locale \u4E0B\u53EF\u80FD\u7559\u4E0B NUL \u4E71\u7801\uFF0C\u9632\u5FA1\u6027\u5254\u9664
  s <- rawToChar(raw)
  Encoding(s) <- "UTF-8"
  lines <- strsplit(s, "\n", fixed = TRUE)[[1]]
  lines <- lines[nzchar(lines)]
  if (!length(lines)) return(invisible(NULL))
  rows <- lapply(utils::tail(lines, n), function(l) {
    tryCatch(jsonlite::parse_json(l, simplifyVector = FALSE), error = function(e) NULL)
  })
  rows <- Filter(Negate(is.null), rows)
  if (!length(rows)) return(invisible(NULL))
  keys <- c("ts", "type", "agent", "tool", "n_calls", "duration_s", "ok", "veto",
    "args_rewritten", "result")
  df <- data.frame(
    lapply(keys, function(k) {
      vapply(rows, function(r) {
        x <- r[[k]] %||% ""
        paste(as.character(x), collapse = " ")
      }, character(1), USE.NAMES = FALSE)
    }),
    stringsAsFactors = FALSE
  )
  names(df) <- keys
  df
}

# ---- \u5DE5\u5177\u6CE8\u518C\u8868 -----------------------------------------------------------

#' \u6CE8\u518C\u81EA\u5B9A\u4E49\u5DE5\u5177\uFF08\u6269\u5C55 Agent \u80FD\u529B\uFF09
#'
#' \u628A\u4E00\u4E2A R \u51FD\u6570\u6CE8\u518C\u4E3A Agent \u53EF\u8C03\u7528\u7684\u5DE5\u5177\uFF1B\u4E0B\u4E00\u6B21\u6253\u5F00\u9762\u677F
#' \uFF08\u6216\u540C\u8FDB\u7A0B\u5185\u518D\u6B21 [dairh_new_agent()] \u65F6\u751F\u6548\uFF09\u3002\u4E0E\u5185\u7F6E\u5DE5\u5177\u540C\u540D\u53EF\u8986\u76D6
#' \uFF08\u9700 `overwrite = TRUE`\uFF09\uFF0C\u53EF\u7528\u6765\u66FF\u6362\u9ED8\u8BA4\u884C\u4E3A\u3002
#'
#' **\u540E\u53F0\u6A21\u5F0F\u6CE8\u610F**\uFF1A\u9762\u677F\u8DD1\u5728\u72EC\u7ACB\u5B50\u8FDB\u7A0B\uFF0C\u4E3B\u4F1A\u8BDD\u7684\u6CE8\u518C\u5BF9\u5B83\u4E0D\u53EF\u89C1\u3002
#' \u8BF7\u628A\u6CE8\u518C\u4EE3\u7801\u5199\u8FDB\u4E00\u4E2A R \u811A\u672C\uFF0C\u5728\u8BBE\u7F6E\u91CC\u628A `tools_profile` \u6307\u5411\u5B83\uFF0C
#' \u9762\u677F\u542F\u52A8\u65F6\u4F1A\u81EA\u52A8 source\uFF08\u540C\u4E00\u8FDB\u7A0B\u540C\u4E00\u6587\u4EF6\u53EA\u6267\u884C\u4E00\u6B21\uFF0C\u6539\u52A8\u540E\u91CD\u5F00\u9762\u677F\u751F\u6548\uFF09\u3002
#'
#' @param name \u5DE5\u5177\u540D\uFF08\u5B57\u6BCD\u5F00\u5934\uFF0C\u4EC5\u5B57\u6BCD/\u6570\u5B57/`_ - .`\uFF0C\u2264 64 \u5B57\u7B26\uFF09
#' @param fn \u5DE5\u5177\u51FD\u6570\uFF0C\u8FD4\u56DE\u5B57\u7B26\u4E32\u7ED3\u679C\uFF08\u975E\u5B57\u7B26\u4E32\u4F1A\u88AB `str()` \u6458\u8981\u5316\uFF09\uFF1B
#'   \u5F62\u53C2\u5FC5\u987B\u4E0E `arguments` \u4E00\u4E00\u5BF9\u5E94
#' @param description \u7ED9\u6A21\u578B\u770B\u7684\u5DE5\u5177\u8BF4\u660E\uFF08\u5199\u6E05\u695A\u4EC0\u4E48\u65F6\u5019\u8BE5\u7528\u3001\u8FD4\u56DE\u4EC0\u4E48\uFF09
#' @param arguments \u547D\u540D\u5217\u8868\uFF0C\u503C\u4E3A `ellmer::type_*()` \u7C7B\u578B\u5B9A\u4E49
#' @param overwrite \u540C\u540D\u5DE5\u5177\uFF08\u542B\u5185\u7F6E\uFF09\u5DF2\u5B58\u5728\u65F6\u662F\u5426\u8986\u76D6
#' @return \u4E0D\u53EF\u89C1\u5730\u8FD4\u56DE\u5DE5\u5177\u540D
#' @examples
#' \dontrun{
#' dairh_register_tool(
#'   "load_my_data",
#'   function(path) paste0("OK: \u5DF2\u52A0\u8F7D ", path),
#'   "\u8BFB\u53D6\u9879\u76EE\u91CC\u7684\u6807\u51C6\u6570\u636E\u6587\u4EF6\u5E76\u8FD4\u56DE\u7ED3\u6784\u6458\u8981\u3002",
#'   arguments = list(path = ellmer::type_string("\u6570\u636E\u6587\u4EF6\u8DEF\u5F84", required = TRUE))
#' )
#' }
#' @export
dairh_register_tool <- function(name, fn, description, arguments = list(), overwrite = FALSE) {
  name <- as.character(name)[[1]]
  if (!grepl("^[A-Za-z][A-Za-z0-9_.-]{0,63}$", name)) {
    stop("\u5DE5\u5177\u540D\u4E0D\u5408\u6CD5\uFF1A", name, "\uFF08\u9700\u5B57\u6BCD\u5F00\u5934\uFF0C\u4EC5\u5B57\u6BCD/\u6570\u5B57/_-. \uFF0C\u2264 64 \u5B57\u7B26\uFF09", call. = FALSE)
  }
  if (!is.function(fn)) stop("fn \u5FC5\u987B\u662F\u51FD\u6570\u3002", call. = FALSE)
  if (!is.character(description) || !length(description) || !nzchar(description[[1]])) {
    stop("description \u5FC5\u987B\u662F\u975E\u7A7A\u5B57\u7B26\u4E32\u3002", call. = FALSE)
  }
  arguments <- if (is.null(arguments)) list() else arguments
  if (!is.list(arguments) ||
      (length(arguments) && (is.null(names(arguments)) || any(!nzchar(names(arguments)))))) {
    stop("arguments \u5FC5\u987B\u662F\u547D\u540D\u5217\u8868\uFF08\u503C\u4E3A ellmer::type_*\uFF09\u3002", call. = FALSE)
  }
  # \u5FEB\u901F\u5931\u8D25\uFF1Afn \u5F62\u53C2\u4E0E arguments \u952E\u5FC5\u987B\u4E00\u4E00\u5BF9\u5E94\uFF08\u4E0E ellmer::tool() \u540C\u89C4\u5219\uFF09\uFF0C
  # \u514D\u5F97\u5230\u6784\u5EFA\u65F6\u624D\u53D1\u73B0\u4E0D\u5339\u914D\u88AB\u9759\u9ED8\u8DF3\u8FC7\u3002
  fm <- names(formals(fn))
  if (length(fm) != length(arguments) ||
      (length(fm) && !setequal(fm, names(arguments)))) {
    stop(sprintf(
      "fn \u7684\u5F62\u53C2\uFF08%s\uFF09\u4E0E arguments \u7684\u952E\uFF08%s\uFF09\u5FC5\u987B\u4E00\u4E00\u5BF9\u5E94\u3002",
      if (length(fm)) paste(fm, collapse = ", ") else "\u65E0",
      if (length(arguments)) paste(names(arguments), collapse = ", ") else "\u65E0"
    ), call. = FALSE)
  }
  is_builtin <- name %in% .dairh_builtin_tools()
  existed <- !is.null(.dairh_harness_env$tools[[name]])
  if ((existed || is_builtin) && !isTRUE(overwrite)) {
    stop(
      sprintf(
        "\u5DE5\u5177 %s \u5DF2\u5B58\u5728\uFF08%s\uFF09\uFF1B\u786E\u8981\u8986\u76D6\u8BF7\u4F20 overwrite = TRUE\u3002",
        name, if (is_builtin) "\u5185\u7F6E" else "\u5DF2\u6CE8\u518C"
      ),
      call. = FALSE
    )
  }
  .dairh_harness_env$tools[[name]] <- list(
    fn = fn,
    description = paste(description, collapse = " "),
    arguments = arguments
  )
  if (is_builtin) message(sprintf("\u5DF2\u8986\u76D6\u5185\u7F6E\u5DE5\u5177 %s\uFF08\u4E0B\u6B21\u6253\u5F00\u9762\u677F\u751F\u6548\uFF09\u3002", name))
  invisible(name)
}

#' \u6CE8\u9500\u5DF2\u6CE8\u518C\u7684\u81EA\u5B9A\u4E49\u5DE5\u5177
#'
#' \u53EA\u80FD\u79FB\u9664 `dairh_register_tool()` \u6CE8\u518C\u7684\u5DE5\u5177\uFF1B\u5185\u7F6E\u5DE5\u5177\u4E0D\u53EF\u6CE8\u9500
#' \uFF08\u53EF\u7528\u540C\u540D\u6CE8\u518C\u8986\u76D6\uFF09\u3002
#'
#' @param name \u5DE5\u5177\u540D
#' @return \u4E0D\u53EF\u89C1 TRUE\uFF1B\u540D\u5B57\u4E0D\u5B58\u5728\u65F6 FALSE
#' @export
dairh_unregister_tool <- function(name) {
  name <- as.character(name)[[1]]
  if (is.null(.dairh_harness_env$tools[[name]])) return(invisible(FALSE))
  .dairh_harness_env$tools[[name]] <- NULL
  invisible(TRUE)
}

#' \u5217\u51FA\u5F53\u524D\u53EF\u7528\u7684\u5DE5\u5177
#'
#' \u8FD4\u56DE\u5185\u7F6E\u5DE5\u5177\u4E0E\u5DF2\u6CE8\u518C\u81EA\u5B9A\u4E49\u5DE5\u5177\u7684\u6E05\u5355\uFF08\u542B\u6765\u6E90\u4E0E\u63CF\u8FF0\uFF09\u3002
#'
#' @return data.frame\uFF08name / source / description\uFF09
#' @export
dairh_list_tools <- function() {
  reg <- .dairh_harness_env$tools
  builtins <- .dairh_builtin_tools()
  rows <- lapply(builtins, function(nm) {
    data.frame(
      name = nm,
      source = if (!is.null(reg[[nm]])) "builtin(\u88AB\u8986\u76D6)" else "builtin",
      description = if (!is.null(reg[[nm]])) reg[[nm]]$description else "\uFF08\u5185\u7F6E\uFF09",
      stringsAsFactors = FALSE
    )
  })
  customs <- setdiff(names(reg), builtins)
  rows <- c(rows, lapply(customs, function(nm) {
    data.frame(
      name = nm, source = "custom",
      description = reg[[nm]]$description,
      stringsAsFactors = FALSE
    )
  }))
  out <- do.call(rbind, rows)
  if (is.null(out)) {
    out <- data.frame(name = character(0), source = character(0), description = character(0),
      stringsAsFactors = FALSE)
  }
  out
}

# ---- \u94A9\u5B50\u7CFB\u7EDF ---------------------------------------------------------------

#' \u6DFB\u52A0 Agent \u94A9\u5B50\uFF08\u5DE5\u5177\u8C03\u7528\u62E6\u622A/\u6539\u5199\uFF09
#'
#' - `pre_tool`\uFF1A\u7B7E\u540D `function(name, args)`\u3002\u5DE5\u5177\u8C03\u7528\u524D\u89E6\u53D1\uFF1B
#'   \u8FD4\u56DE\u5B57\u7B26\u4E32\u5373\u62E6\u622A\u672C\u6B21\u8C03\u7528\uFF08\u6A21\u578B\u6536\u5230 `FAIL: \uFF08\u94A9\u5B50\u62E6\u622A ... \uFF09` \uFF09\uFF0C
#'   \u8FD4\u56DE NULL \u653E\u884C\u3002\u53EF\u7528\u4E8E\u5BA1\u8BA1\u3001\u5C01\u7981\u67D0\u4E9B\u8DEF\u5F84\u3001\u654F\u611F\u64CD\u4F5C\u786E\u8BA4\u63D0\u9192\u7B49\u3002
#' - `post_tool`\uFF1A\u7B7E\u540D `function(name, args, result)`\u3002\u5DE5\u5177\u8FD4\u56DE\u540E\u89E6\u53D1\uFF1B
#'   \u8FD4\u56DE\u5B57\u7B26\u4E32\u5219\u66FF\u6362\u5DE5\u5177\u7ED3\u679C\uFF08\u53EF\u505A\u8131\u654F/\u6CE8\u91CA\uFF09\uFF0C\u8FD4\u56DE NULL \u4FDD\u7559\u539F\u7ED3\u679C\u3002
#'
#' \u94A9\u5B50\u62DB\u94FE\u63A5\u6837\u6309\u6CE8\u518C\u987A\u5E8F\u6267\u884C\uFF1B\u94A9\u5B50\u81EA\u8EAB\u62A5\u9519\u53EA warning \u4E0D\u4F1A\u70B8\u9762\u677F\u3002
#'
#' @param stage "pre_tool" \u6216 "post_tool"
#' @param fn \u94A9\u5B50\u51FD\u6570\uFF08\u7B7E\u540D\u89C1\u4E0A\uFF09
#' @param name \u53EF\u9009\u7684\u94A9\u5B50\u540D\uFF08\u79FB\u9664\u65F6\u7528\uFF1B\u7F3A\u7701\u81EA\u52A8\u7F16\u53F7\uFF09
#' @return \u4E00\u4E2A\u65E0\u53C2\u51FD\u6570\uFF0C\u8C03\u7528\u5373\u79FB\u9664\u6B64\u94A9\u5B50\uFF08\u4E0E ellmer \u7684 add \u98CE\u683C\u4E00\u81F4\uFF09
#' @examples
#' \dontrun{
#' # \u7981\u6B62 Agent \u78B0\u4EFB\u4F55 .Renviron\uFF08\u9632\u628A\u91CC\u9762\u7684 key \u5199\u8FDB\u5BF9\u8BDD\uFF09
#' dairh_add_hook("pre_tool", function(name, args) {
#'   if (name %in% c("read_file", "edit_file") &&
#'       grepl("Renviron|\\.env$", args$path %||% "")) "\u654F\u611F\u6587\u4EF6\u7981\u6B62\u8BFB\u5199"
#' })
#' }
#' @export
dairh_add_hook <- function(stage, fn, name = NULL) {
  stage <- match.arg(stage, c("pre_tool", "post_tool"))
  if (!is.function(fn)) stop("fn \u5FC5\u987B\u662F\u51FD\u6570\u3002", call. = FALSE)
  need <- if (identical(stage, "pre_tool")) 2L else 3L
  fm <- names(formals(fn))
  if (!length(fm) || (!"..." %in% fm && length(fm) < need)) {
    stop(sprintf("%s \u94A9\u5B50\u81F3\u5C11\u9700\u8981 %d \u4E2A\u53C2\u6570\uFF08\u7B7E\u540D\u89C1 help\uFF09\u3002", stage, need), call. = FALSE)
  }
  store <- .dairh_harness_env$hooks[[stage]]
  if (is.null(name) || !is.character(name) || !nzchar(name[[1]])) {
    name <- sprintf("hook%d", length(store) + 1L)
  } else {
    name <- name[[1]]
  }
  store[[name]] <- fn
  .dairh_harness_env$hooks[[stage]] <- store
  invisible(function() dairh_remove_hook(stage, name))
}

#' \u79FB\u9664\u94A9\u5B50
#'
#' @param stage "pre_tool" \u6216 "post_tool"
#' @param name \u94A9\u5B50\u540D\uFF08[dairh_add_hook()] \u65F6\u6307\u5B9A\u6216\u81EA\u52A8\u7F16\u53F7\u7684\u90A3\u4E2A\uFF09
#' @return \u4E0D\u53EF\u89C1 TRUE\uFF1B\u540D\u5B57\u4E0D\u5B58\u5728\u65F6 FALSE
#' @export
dairh_remove_hook <- function(stage, name) {
  stage <- match.arg(stage, c("pre_tool", "post_tool"))
  name <- as.character(name)[[1]]
  if (is.null(.dairh_harness_env$hooks[[stage]][[name]])) return(invisible(FALSE))
  .dairh_harness_env$hooks[[stage]][[name]] <- NULL
  invisible(TRUE)
}

#' \u6784\u9020 pre_tool \u94A9\u5B50\u7684\u53C2\u6570\u6539\u5199\u8FD4\u56DE\u503C
#'
#' \u5728 `pre_tool` \u94A9\u5B50\u91CC\u8FD4\u56DE\u672C\u5BF9\u8C61\uFF08\u800C\u4E0D\u662F\u5B57\u7B26\u4E32/NULL\uFF09\uFF0C\u5373\u53EF**\u6539\u5199**\u672C\u6B21\u5DE5\u5177\u8C03\u7528\u7684
#' \u53C2\u6570\uFF1A\u540E\u7EED\u94A9\u5B50\u4E0E\u5DE5\u5177\u672C\u8EAB\u6536\u5230\u7684\u90FD\u662F\u6539\u5199\u540E\u7684\u53C2\u6570\uFF0C\u6539\u5199\u52A8\u4F5C\u8BB0\u5165 trace
#' \uFF08`args_rewritten` \u5B57\u6BB5\uFF0C\u542B\u94A9\u5B50\u540D\u94FE\uFF09\u3002\u5B57\u7B26\u4E32 = \u62E6\u622A\u3001NULL = \u653E\u884C\u7684\u539F\u8BED\u4E49\u4E0D\u53D8\u3002
#'
#' @param args \u6539\u5199\u540E\u7684\u53C2\u6570\uFF08\u547D\u540D\u5217\u8868\uFF0C\u952E\u4E0E\u5DE5\u5177\u5F62\u53C2\u4E00\u81F4\uFF1B\u6574\u5305\u66FF\u6362\uFF0C\u4E0D\u505A\u6DF1\u5408\u5E76\uFF09
#' @return \u5E26\u6807\u8BB0\u7684\u6539\u5199\u5BF9\u8C61\uFF08\u4EC5\u4F5C\u4E3A pre_tool \u94A9\u5B50\u7684\u8FD4\u56DE\u503C\u4F7F\u7528\uFF09
#' @examples
#' \dontrun{
#' # \u7ED9 run_r_code \u7684\u8C03\u7528\u7EDF\u4E00\u6536\u7D27\u8D85\u65F6\uFF08\u53C2\u6570\u6539\u5199\u793A\u4F8B\uFF09
#' dairh_add_hook("pre_tool", function(name, args) {
#'   if (identical(name, "run_r_code") && is.character(args$code)) {
#'     dairh_rewrite_args(list(code = args$code, timeout_sec = 120))
#'   }
#' })
#' }
#' @export
dairh_rewrite_args <- function(args) {
  if (!is.list(args)) stop("args \u5FC5\u987B\u662F\u547D\u540D\u5217\u8868\u3002", call. = FALSE)
  if (length(args) && (is.null(names(args)) || any(!nzchar(names(args))))) {
    stop("args \u5FC5\u987B\u662F\u547D\u540D\u5217\u8868\uFF08\u952E\u4E0E\u5DE5\u5177\u5F62\u53C2\u4E00\u81F4\uFF09\u3002", call. = FALSE)
  }
  structure(list(args = args), class = "dairh_hook_rewrite")
}

# ---- \u5DE5\u5177\u5305\u88C5\u5668\uFF08\u94A9\u5B50 + \u9884\u7B97 + trace \u7684\u7EDF\u4E00\u5165\u53E3\uFF09------------------------

# \u628A\u4EFB\u610F\u5DE5\u5177\u51FD\u6570\u5305\u6210\u5E26 harness \u80FD\u529B\u7684 ellmer ToolDef\u3002
# \u5F62\u53C2\u5FC5\u987B\u9010\u4E00\u590D\u5236\uFF08ellmer::tool() \u4F1A\u6821\u9A8C formals \u4E0E arguments \u4E00\u81F4\uFF09\uFF0C
# \u5E76\u663E\u5F0F\u4F20 name \u2014\u2014 \u5426\u5219\u533F\u540D\u51FD\u6570\u4F1A\u88AB\u547D\u540D\u6210 tool_001 \u8FD9\u7C7B\u5783\u573E\u540D\uFF08\u5DF2\u8E0F\u8FC7\u7684\u5751\uFF09\u3002
.dairh_wrap_tool <- function(name, fn, description, arguments, state) {
  # arguments \u652F\u6301\u4E24\u79CD\u5F62\u6001\uFF1A\u547D\u540D list\uFF08\u6CE8\u518C\u8868\uFF09\u6216 ToolDef \u7684 TypeObject\uFF08\u5185\u7F6E\u5DE5\u5177\uFF09
  props <- tryCatch(arguments@properties, error = function(e) NULL)
  if (!is.null(props)) arguments <- props
  wrapper <- function() NULL
  formals(wrapper) <- formals(fn)
  fn_env <- environment(fn)
  env_ <- new.env(parent = if (is.environment(fn_env)) fn_env else baseenv())
  environment(wrapper) <- env_
  assign(".__fn__.", fn, envir = env_)
  assign(".__state__.", state, envir = env_)
  assign(".__name__.", name, envir = env_)
  assign(".__invoke__.", .dairh_tool_invoke, envir = env_)
  body(wrapper) <- substitute({
    .__a__. <- as.list(environment())
    .__invoke__.(.__name__., .__fn__., .__a__., .__state__.)
  })
  # \u6CE8\u610F\uFF1Aarguments \u5FC5\u987B\u547D\u540D\u4F20\u53C2\u2014\u2014 tool() \u7684\u7B2C\u4E09\u4E2A\u4F4D\u7F6E\u53C2\u6570\u662F\u5E9F\u5F03\u7684 ...
  ellmer::tool(wrapper, description, arguments = arguments, name = name)
}

# \u975E\u5B57\u7B26\u4E32\u8FD4\u56DE\u503C\u6458\u8981\u5316\uFF08\u81EA\u5B9A\u4E49\u5DE5\u5177\u53EF\u80FD\u56FE\u7701\u4E8B\u76F4\u63A5\u8FD4\u56DE\u5BF9\u8C61\uFF09
.dairh_result_text <- function(res) {
  if (is.null(res)) return("")
  if (is.character(res) && length(res)) return(paste(res, collapse = "\n"))
  out <- tryCatch(
    utils::capture.output(str(res, max.level = 2, vec.len = 6)),
    error = function(e) paste(deparse(res), collapse = "\n")
  )
  paste(out, collapse = "\n")
}

# Content \u7ED3\u679C\u7684 trace \u6458\u8981\uFF1A\u6587\u672C\u90E8\u5206\u53D6 text\uFF0C\u5176\u4F59\u53D6\u7C7B\u540D\uFF08\u56FE\u7247\u672C\u8EAB\u4E0D\u8FDB trace\uFF0C\u53EA\u7559\u7C7B\u540D\u75D5\u8FF9\uFF09
.dai_content_brief <- function(res) {
  parts <- if (inherits(res, "ellmer::Content")) list(res) else res
  out <- vapply(parts, function(el) {
    if (inherits(el, "ellmer::ContentText")) paste(el@text, collapse = " ") else class(el)[[1]]
  }, character(1))
  paste(out, collapse = " | ")
}

.dairh_args_json <- function(args) {
  tryCatch(
    jsonlite::toJSON(args, auto_unbox = TRUE, null = "null"),
    error = function(e) {
      paste(utils::capture.output(str(args, max.level = 2)), collapse = "\n")
    }
  )
}

# \u56DE\u5408\u68C0\u6D4B\uFF1A\u6570 client \u5BF9\u8BDD\u91CC"\u771F\u7528\u6237\u6D88\u606F"\u7684\u56DE\u5408\u6570\uFF1B\u53D8\u591A\u5373\u65B0\u4E00\u8F6E \u2192 \u9884\u7B97\u6E05\u96F6\u3002
# \u5173\u952E\uFF1Aellmer \u628A\u5DE5\u5177\u7ED3\u679C\u4E5F\u5B58\u6210 role="user" \u7684\u56DE\u5408\uFF0C\u4F46\u5176 @text \u4E3A\u7A7A\uFF08\u5B9E\u6D4B\u786E\u8BA4\uFF09\uFF1B
# \u53EA\u6570 @text \u975E\u7A7A\u7684 user \u56DE\u5408\uFF0C\u5426\u5219\u6BCF\u6B21\u5DE5\u5177\u8C03\u7528\u540E\u90FD\u4F1A\u88AB\u8BEF\u5224\u6210\u65B0\u56DE\u5408\u3001\u9884\u7B97\u6C38\u8FDC\u91CD\u7F6E\u3002
.dairh_budget_turn_reset <- function(state) {
  if (is.null(state$client)) return(invisible(FALSE))
  un <- tryCatch(
    {
      ts <- state$client$get_turns()
      if (!length(ts)) 0L else sum(vapply(ts, function(t) {
        identical(as.character(t@role), "user") &&
          length(t@text) > 0L && nzchar(t@text)
      }, logical(1)))
    },
    error = function(e) NA_integer_
  )
  if (is.na(un)) return(invisible(FALSE))
  new_turn <- !is.na(state$last_user_n) && un > state$last_user_n
  if (new_turn && state$n_calls > 0L) {
    state$n_calls <- 0L
    .dairh_trace_write(state, list(
      ts = format(Sys.time(), "%Y-%m-%d %H:%M:%OS3"),
      pid = Sys.getpid(),
      type = "turn_reset",
      user_turns = un
    ))
  }
  state$last_user_n <- un
  invisible(new_turn)
}

# \u5DE5\u5177\u8C03\u7528\u7684\u7EDF\u4E00\u901A\u9053\uFF1A\u9884\u7B97\u2192 pre \u94A9\u5B50\u2192 \u6267\u884C\u2192 post \u94A9\u5B50\u2192 trace
.dairh_tool_invoke <- function(name, fn, args, state) {
  t0 <- Sys.time()
  .dairh_budget_turn_reset(state)
  budget <- state$budget
  over <- !is.null(budget) && is.finite(budget) && state$n_calls >= budget
  state$n_calls <- state$n_calls + 1L

  veto <- NA_character_
  if (over) {
    veto <- "budget"
    result <- paste0(
      "FAIL: \uFF08\u786C\u9884\u7B97\uFF09\u672C\u8F6E\u5DE5\u5177\u8C03\u7528\u5DF2\u8FBE\u786C\u4E0A\u9650 ",
      budget,
      " \u6B65\uFF0C\u672C\u6B21\u8C03\u7528\u88AB\u62E6\u622A\u3002\u8BF7\u4E0D\u8981\u518D\u7EE7\u7EED\u8C03\u7528\u5DE5\u5177\uFF1A",
      "\u57FA\u4E8E\u5DF2\u83B7\u5F97\u7684\u4FE1\u606F\u603B\u7ED3\u9636\u6BB5\u6027\u6210\u679C\u5E76\u56DE\u7B54\u7528\u6237\uFF1B",
      "\u82E5\u4EFB\u52A1\u786E\u5B9E\u672A\u5B8C\u6210\uFF0C\u8BF4\u660E\u5269\u4F59\u6B65\u9AA4\uFF0C\u7528\u6237\u4E0B\u4E00\u8F6E\u6D88\u606F\u4F1A\u91CD\u7F6E\u9884\u7B97\u540E\u7EE7\u7EED\u3002"
    )
  } else {
    result <- NULL
    # pre_tool \u94A9\u5B50\uFF1A\u5B57\u7B26\u4E32 = \u62E6\u622A\uFF1Bdairh_rewrite_args() = \u6539\u5199\u53C2\u6570\u540E\u653E\u884C\uFF08\u540E\u7EED\u94A9\u5B50\u89C1\u65B0\u53C2\u6570\uFF09
    hooks <- .dairh_harness_env$hooks$pre_tool
    rewritten_by <- character(0)
    for (nm in names(hooks)) {
      v <- tryCatch(
        hooks[[nm]](name, args),
        error = function(e) {
          warning(sprintf("DaiRH pre_tool \u94A9\u5B50 '%s' \u51FA\u9519\uFF1A%s", nm, conditionMessage(e)),
            call. = FALSE)
          NULL
        }
      )
      if (inherits(v, "dairh_hook_rewrite")) {
        if (!is.list(v$args)) {
          warning(sprintf("DaiRH pre_tool \u94A9\u5B50 '%s' \u7684\u6539\u5199\u503C\u4E0D\u5408\u6CD5\uFF08\u9700\u547D\u540D list\uFF09\uFF0C\u5DF2\u5FFD\u7565\u3002", nm),
            call. = FALSE)
          next
        }
        args <- v$args
        rewritten_by <- c(rewritten_by, nm)
        next
      }
      if (is.character(v) && length(v) >= 1L && nzchar(v[[1]])) {
        veto <- paste0("hook:", nm)
        result <- paste0("FAIL: \uFF08\u94A9\u5B50\u62E6\u622A ", nm, "\uFF09", paste(v, collapse = " "))
        break
      }
    }
    if (is.null(result)) {
      res <- tryCatch(
        do.call(fn, args),
        error = function(e) paste0("FAIL: ", conditionMessage(e))
      )
      # ellmer 0.5 \u5141\u8BB8\u5DE5\u5177\u8FD4\u56DE Content / Content \u5217\u8868\uFF08show_plot \u7684\u56FE\u7247\u76F4\u8FD4\u5373\u6B64\uFF09\uFF1A
      # \u539F\u6837\u900F\u4F20\u7ED9 ellmer\uFF0C\u4E0D\u505A\u6587\u672C\u6458\u8981\u5316\uFF1Bpost \u94A9\u5B50\u9762\u5411\u6587\u672C\uFF0C\u6B64\u8DEF\u8DF3\u8FC7\u3002
      res_content <- inherits(res, "ellmer::Content") ||
        (is.list(res) && length(res) > 0L &&
          all(vapply(res, inherits, logical(1), "ellmer::Content")))
      if (res_content) {
        result <- res
        res_text <- .dai_content_brief(res)
      } else {
        res_text <- .dairh_result_text(res)
        # post_tool \u94A9\u5B50\uFF1A\u8FD4\u56DE\u5B57\u7B26\u4E32\u5219\u66FF\u6362\u7ED3\u679C
        hooks2 <- .dairh_harness_env$hooks$post_tool
        for (nm in names(hooks2)) {
          r2 <- tryCatch(
            hooks2[[nm]](name, args, res_text),
            error = function(e) {
              warning(sprintf("DaiRH post_tool \u94A9\u5B50 '%s' \u51FA\u9519\uFF1A%s", nm, conditionMessage(e)),
                call. = FALSE)
              NULL
            }
          )
          if (is.character(r2) && length(r2) >= 1L) res_text <- paste(r2, collapse = "\n")
        }
        result <- res_text
      }
    }
  }

  ok <- if (is.character(result)) !startsWith(result, "FAIL") else TRUE
  dur <- as.numeric(difftime(Sys.time(), t0, units = "secs"))
  trace_result <- if (is.character(result)) result else .dai_content_brief(result)
  .dairh_trace_write(state, list(
    ts = format(t0, "%Y-%m-%d %H:%M:%OS3"),
    pid = Sys.getpid(),
    agent = state$tag %||% "main",
    type = "tool",
    tool = name,
    n_calls = state$n_calls,
    args = .dai_clip(.dairh_args_json(args), 2000),
    args_rewritten = if (length(rewritten_by)) paste(rewritten_by, collapse = ",") else NULL,
    duration_s = round(dur, 3),
    ok = ok,
    veto = veto,
    result = .dai_clip(trace_result, 400)
  ))
  result
}

# ---- tools_profile \uFF08\u81EA\u5B9A\u4E49\u5DE5\u5177/\u94A9\u5B50\u7684\u8DE8\u8FDB\u7A0B\u901A\u9053\uFF09--------------------------

# \u6BCF\u8FDB\u7A0B\u6BCF\u6587\u4EF6\u53EA source \u4E00\u6B21\uFF08\u6309 mtime \u5931\u6548\u91CD\u8F7D\uFF09\uFF1B\u62A5\u9519\u53EA warning \u4E0D\u963B\u65AD\u9762\u677F\u3002
.dairh_source_profile <- function(cfg = dairh_config_get()) {
  p <- cfg$tools_profile %||% ""
  if (!is.character(p) || length(p) != 1L || !nzchar(trimws(p))) return(invisible(FALSE))
  p <- normalizePath(trimws(p), winslash = "/", mustWork = FALSE)
  mt <- suppressWarnings(file.info(p)$mtime)
  if (length(mt) != 1L || is.na(mt)) {
    warning("tools_profile \u6587\u4EF6\u4E0D\u5B58\u5728\uFF1A", p, call. = FALSE)
    return(invisible(FALSE))
  }
  mt_key <- as.character(mt)
  rec <- .dairh_harness_env$profiles[[p]]
  if (!is.null(rec) && identical(rec, mt_key)) return(invisible(TRUE))
  ok <- tryCatch(
    {
      source(p, local = new.env(parent = globalenv()), keep.source = FALSE)
      TRUE
    },
    error = function(e) {
      warning("tools_profile \u6267\u884C\u5931\u8D25\uFF08", p, "\uFF09\uFF1A", conditionMessage(e), call. = FALSE)
      FALSE
    }
  )
  if (ok) .dairh_harness_env$profiles[[p]] <- mt_key
  invisible(ok)
}
