# DaiRH \u540E\u53F0\u8FD0\u884C\u6A21\u5F0F ---------------------------------------------------------
# \u76EE\u6807\uFF1A\u6DFB\u52A0\u9762\u677F\u4E0D\u518D\u9501\u6B7B R \u63A7\u5236\u53F0\u3002
#
# \u673A\u5236\uFF1A
#   - \u9762\u677F Shiny \u5E94\u7528\u8DD1\u5728 callr::r_bg \u5B50\u8FDB\u7A0B\u91CC\uFF08\u63A7\u5236\u53F0\u7ACB\u5373\u7A7A\u95F2\uFF09
#   - \u4E3B\u4F1A\u8BDD\u5185\u8D77\u4E00\u4E2A"\u80FD\u529B\u6865"\uFF08\u6587\u4EF6\u6865\uFF0Cv2\uFF09\u5411\u5B50\u8FDB\u7A0B\u63D0\u4F9B\u4F9D\u8D56
#     RStudio \u4E3B\u4F1A\u8BDD\u7684\u80FD\u529B\uFF1Acontext / workspace / base_dir / nav\u3002
#     \u5B50\u8FDB\u7A0B\u5199\u8BF7\u6C42\u6587\u4EF6\uFF0C\u4E3B\u4F1A\u8BDD\u7684 later \u5FAA\u73AF\u5904\u7406\u5E76\u5199\u56DE\u54CD\u5E94\uFF1B
#     \u65E7\u7248 httpuv socket \u6865\u56E0 RStudio \u7A7A\u95F2\u65F6\u4E0D\u9A71\u52A8\u5176\u670D\u52A1\u5FAA\u73AF\uFF08
#     \u5B9E\u6D4B\u8FDE\u4E0A\u540E 0 bytes received\uFF09\u5DF2\u5E9F\u5F03\u3002
#   - \u6865\u4E0D\u53EF\u7528\u65F6\u56DE\u9000\uFF1A\u542F\u52A8\u65F6\u5FEB\u7167 + \u5B50\u8FDB\u7A0B\u672C\u5730\u5B9E\u73B0
#   - \u5173\u95ED\u9762\u677F\u6807\u7B7E \u2192 shiny session \u5168\u90E8\u7ED3\u675F \u2192 \u5B50\u8FDB\u7A0B\u81EA\u52A8\u9000\u51FA
#     \uFF08callr::r_bg supervise=TRUE \u4FDD\u8BC1 RStudio \u9000\u51FA\u65F6\u4E00\u5E76\u6E05\u7406\uFF09

# ---- \u7AEF\u53E3\u5C0F\u5DE5\u5177 -------------------------------------------------------------
# \u6CE8\u610F\uFF1A\u90E8\u5206 Windows \u6784\u5EFA\u91CC httpuv::startServer(port=0) \u540E getPort() \u4ECD\u8FD4\u56DE 0\uFF0C
# \u56E0\u6B64\u8FD9\u91CC\u7528 "\u968F\u673A\u5019\u9009\u7AEF\u53E3 + \u7ED1\u5B9A\u5C1D\u8BD5" \u9009\u53E3\uFF0C\u800C\u4E0D\u662F port=0 \u8BA9\u7CFB\u7EDF\u5206\u914D\u3002
.dairh_free_port <- function() {
  for (i in 1:25) {
    cand <- as.integer(20000 + (runif(1) * 25000))
    s <- tryCatch(
      httpuv::startServer("127.0.0.1", cand, list(call = function(req) NULL)),
      error = function(e) NULL
    )
    if (is.null(s)) next
    p <- tryCatch(s$getPort(), error = function(e) NULL)
    tryCatch(httpuv::stopServer(s), error = function(e) NULL)
    if (!is.null(p) && p > 0L) return(as.integer(p))
  }
  NA_integer_
}

.dairh_bridge_env <- new.env(parent = emptyenv())
# \u540E\u53F0\u9762\u677F\u5B50\u8FDB\u7A0B\u7684\u5F3A\u5F15\u7528\u4ED3\u5E93\uFF1A
# callr::r_bg(supervise=TRUE) \u7528 Windows Job Object\uFF08job \u5173\u95ED\u5373\u6740\u8FDB\u7A0B\uFF09\u3002
# \u82E5\u53E5\u67C4\u5BF9\u8C61\u88AB GC\uFF0Cjob \u5173\u95ED -> \u9762\u677F"\u521A\u542F\u52A8\u5C31\u6B7B"\u3002\u5FC5\u987B\u5168\u5C40\u6301\u6709\u3002
.dairh_bg_children <- new.env(parent = emptyenv())

# ---- \u80FD\u529B\u6865\uFF08\u6587\u4EF6\u7248 v2\uFF09 ------------------------------------------------
# \u65E7\u7248\u662F httpuv socket \u6865\uFF1A\u5B9E\u6D4B RStudio \u7A7A\u95F2\u65F6\u4E0D\u9A71\u52A8 httpuv \u670D\u52A1\u5FAA\u73AF
# \uFF08\u5B50\u8FDB\u7A0B\u8FDE\u4E0A\u4E86\u4F46 0 bytes received\uFF09\uFF0C\u5FC5\u987B\u629B\u5F03\u3002
# \u65B0\u7248\u6539\u6210\u6587\u4EF6\u6865\uFF1A
#   \u5B50\u8FDB\u7A0B \u5199\u8BF7\u6C42\u6587\u4EF6 req-<nonce>.json \u2192 \u8F6E\u8BE2 resp-<nonce>.json\uFF08\u22643s\uFF09
#   \u4E3B\u4F1A\u8BDD later \u5FAA\u73AF\uFF080.4s\uFF09\u626B\u8BF7\u6C42\u2192\u5728 RStudio \u91CC\u6267\u884C\u2192\u5199\u54CD\u5E94\u2192\u5220\u8BF7\u6C42
# RStudio \u7A7A\u95F2\u65F6\u4F1A\u6267\u884C later \u56DE\u8C03\uFF08\u5B9E\u8BC1\uFF1Astderr \u955C\u50CF\u5FAA\u73AF\u5728\u7528\u6237\u673A\u5668\u4E0A\u6709\u89E6\u53D1\u8FC7\uFF09\uFF0C
# \u6587\u4EF6\u6865\u4E0D\u4F9D\u8D56 socket accept\uFF0C\u53EA\u4F9D\u8D56 later \uFF0C\u56E0\u6B64\u5728\u771F\u5B9E RStudio \u91CC\u53EF\u7528\u3002

.dairh_bridge_dir <- function() {
  dir <- file.path(tools::R_user_dir("daiRH", "cache"), "bridge")
  dir.create(dir, recursive = TRUE, showWarnings = FALSE)
  dir
}

.dairh_bridge_nonce <- function() {
  format(Sys.time(), "%H%M%OS3") %||% ""
}

#' \u542F\u52A8/\u590D\u7528\u4E3B\u4F1A\u8BDD\u5185\u7684 RStudio \u80FD\u529B\u6865\uFF08\u540E\u53F0\u9762\u677F\u6A21\u5F0F\uFF09
#'
#' \u5E42\u7B49\uFF1A\u5DF2\u6709\u5B58\u6D3B\u6865\u65F6\u76F4\u63A5\u8FD4\u56DE\u3002\u8FD4\u56DE\u5171\u4EAB\u76EE\u5F55\u8DEF\u5F84\uFF1B\u5931\u8D25\u8FD4\u56DE ""\u3002
#' \u4E3B\u4F1A\u8BDD\u4FA7\u8D77\u4E00\u4E2A later \u8F6E\u8BE2\u5FAA\u73AF\u5904\u7406\u8BF7\u6C42\u6587\u4EF6\uFF08RStudio \u7A7A\u95F2\u65F6\u4F1A\u6267\u884C later\uFF09\u3002
dairh_bridge_start <- function() {
  old <- .dairh_bridge_env$dir
  if (!is.null(old) && isTRUE(.dairh_bridge_env$pumping)) {
    return(old)
  }
  dir <- .dairh_bridge_dir()
  # \u6E05\u7406\u4E0A\u4E00\u4EFB\u8BF7\u6C42/\u54CD\u5E94/\u81EA\u68C0\u6B8B\u7559\uFF08\u4E0D\u52A8 context-snapshot.json\uFF09
  for (f in list.files(dir, pattern = "^(req|resp|selftest)-.*\\.json$", full.names = TRUE)) {
    tryCatch(file.remove(f), error = function(e) NULL)
  }
  .dairh_bridge_env$dir <- dir
  .dairh_bridge_env$pumping <- TRUE
  .dairh_start_bridge_pump(dir)
  dir
}

# \u4E3B\u4F1A\u8BDD\u4FA7\uFF1Alater \u5FAA\u73AF\u5904\u7406\u8BF7\u6C42\u6587\u4EF6\uFF1B\u6BCF\u6B21\u88AB\u9A71\u52A8\u90FD\u987A\u624B\u5237\u65B0
# \u7F16\u8F91\u5668\u4E0A\u4E0B\u6587\u5FEB\u7167\uFF08\u5FEB\u7167\u5F0F\u67B6\u6784\uFF1A\u9762\u677F\u53EA\u8BFB\u5FEB\u7167\u6587\u4EF6\uFF0C\u4E0D\u505A\u5F80\u8FD4\u8BF7\u6C42\uFF09\u3002
# \u5B9E\u6D4B RStudio \u53EA\u5728\u63A7\u5236\u53F0\u4EFB\u52A1\u8FB9\u754C\uFF08\u56DE\u8F66/\u547D\u4EE4\u7ED3\u675F\uFF09\u6267\u884C later\uFF0C
# \u56E0\u6B64\u5FEB\u7167\u65B0\u9C9C\u5EA6 = \u6700\u8FD1\u4E00\u6B21\u63A7\u5236\u53F0\u6D3B\u52A8\u3002
.dairh_start_bridge_pump <- function(dir, interval = 0.4, max_ticks = 54000L) {
  if (!requireNamespace("later", quietly = TRUE)) return(invisible(NULL))
  ticks_left <- max_ticks
  step <- function() {
    if (!isTRUE(.dairh_bridge_env$pumping)) return(invisible(NULL))
    ticks_left <<- ticks_left - 1L
    # \u5237\u65B0\u7F16\u8F91\u5668\u4E0A\u4E0B\u6587\u5FEB\u7167\uFF08\u6CF5\u88AB\u9A71\u52A8 = \u63A7\u5236\u53F0\u6709\u6D3B\u52A8\u8FB9\u754C\uFF09
    tryCatch({
      snap <- list(
        time = format(Sys.time(), "%H:%M:%S"),
        base_dir = dairh_base_dir(),
        context = dairh_editor_context_text()
      )
      writeLines(jsonlite::toJSON(snap, auto_unbox = TRUE, null = "null"),
        file.path(dir, "context-snapshot.json"), useBytes = TRUE)
    }, error = function(e) NULL)
    reqs <- tryCatch(
      list.files(dir, pattern = "^req-.*\\.json$", full.names = TRUE),
      error = function(e) character(0)
    )
    for (rf in reqs) {
      ok <- tryCatch({
        j <- jsonlite::fromJSON(rf, simplifyVector = FALSE)
        res <- .dairh_bridge_exec(j$op %||% "", j$args %||% list())
        resp <- file.path(dir, paste0("resp-", sub("^req-", "", basename(rf))))
        writeLines(jsonlite::toJSON(list(ok = TRUE, result = res),
          auto_unbox = TRUE, null = "null"), resp, useBytes = TRUE)
        TRUE
      }, error = function(e) {
        resp <- file.path(dir, paste0("resp-", sub("^req-", "", basename(rf))))
        tryCatch(writeLines(jsonlite::toJSON(list(
          ok = FALSE, error = conditionMessage(e)
        ), auto_unbox = TRUE), resp, useBytes = TRUE), error = function(e2) NULL)
        FALSE
      })
      tryCatch(file.remove(rf), error = function(e) NULL)
      if (!ok) invisible(NULL)
    }
    if (ticks_left > 0L) later::later(step, interval)
  }
  later::later(step, interval)
  invisible(NULL)
}

# \u4E3B\u4F1A\u8BDD\u4FA7\u6267\u884C\u5668\uFF1Aop \u2192 \u5728 RStudio \u91CC\u771F\u6B63\u5E72\u6D3B
.dairh_bridge_exec <- function(op, args) {
  switch(op,
    context = dairh_editor_context_text(),
    base_dir = dairh_base_dir(),
    workspace = .dai_workspace_summary(),
    nav = {
      p <- as.character(args$path %||% "")
      l <- suppressWarnings(as.integer(args$line %||% 1))
      if (nzchar(p) && isTRUE(dairh_nav(p, l))) "ok" else "fail"
    },
    stop("unknown bridge op: ", op)
  )
}

# \u5B50\u8FDB\u7A0B\u4FA7\uFF1A\u5199\u8BF7\u6C42 + \u8F6E\u8BE2\u54CD\u5E94\uFF08\u2264 timeout_s\uFF09\u3002
# \u8FD4\u56DE character \u7ED3\u679C\uFF1B\u5931\u8D25\u65F6 character(0) \u5E26 attr "bridge_fail"\u3002
.dairh_bridge_call <- function(op, args = list(), timeout_s = 3) {
  dir <- getOption("daiRH.bridge_dir") %||% ""
  if (!nzchar(dir) || !dir.exists(dir)) {
    return(`attr<-`(character(0), "bridge_fail", "not-configured"))
  }
  nonce <- paste0(gsub("[:.]", "", format(Sys.time(), "%H%M%OS3")),
    "-", as.integer(runif(1, 1, 1e9)))
  rf <- file.path(dir, paste0("req-", nonce, ".json"))
  pf <- file.path(dir, paste0("resp-", nonce, ".json"))
  ok <- tryCatch({
    writeLines(jsonlite::toJSON(list(op = op, args = args),
      auto_unbox = TRUE, null = "null"), rf, useBytes = TRUE)
    TRUE
  }, error = function(e) FALSE)
  if (!ok) return(`attr<-`(character(0), "bridge_fail", "req-write-failed"))
  on.exit(tryCatch(file.remove(rf), error = function(e) NULL), add = TRUE)
  t0 <- Sys.time()
  while (difftime(Sys.time(), t0, units = "secs") < timeout_s) {
    if (file.exists(pf)) {
      j <- tryCatch(
        jsonlite::fromJSON(pf, simplifyVector = FALSE),
        error = function(e) NULL
      )
      tryCatch(file.remove(pf), error = function(e) NULL)
      if (is.null(j)) {
        return(`attr<-`(character(0), "bridge_fail", "resp-parse-failed"))
      }
      if (!isTRUE(j$ok)) {
        return(`attr<-`(character(0), "bridge_fail",
          paste0("op-failed:", .dai_clip(as.character(j$error %||% "?"), 80))))
      }
      res <- j$result
      txt <- if (is.null(res)) "" else paste(as.character(res), collapse = "\n")
      return(txt)
    }
    Sys.sleep(0.2)
  }
  `attr<-`(character(0), "bridge_fail", "timeout")
}

.dairh_parse_query <- function(qs) {
  parts <- strsplit(qs, "&", fixed = TRUE)[[1]]
  kv <- strsplit(parts, "=", fixed = TRUE)
  out <- list()
  for (pair in kv) {
    if (length(pair) >= 1L && nzchar(pair[1])) {
      val <- if (length(pair) >= 2L) utils::URLdecode(pair[2]) else ""
      out[[pair[1]]] <- val
    }
  }
  out
}

# \u8DEF\u5F84\u98CE\u683C\u5165\u53E3\uFF08\u517C\u5BB9\u65E7\u8C03\u7528\u70B9\uFF09\uFF1A"/context" \u7B49 \u2192 \u6587\u4EF6\u6865 op \u8C03\u7528
.dairh_bridge_get <- function(path, query = list()) {
  op <- switch(path,
    "/context" = "context",
    "/base_dir" = "base_dir",
    "/workspace" = "workspace",
    "/nav" = "nav",
    ""
  )
  if (!nzchar(op)) {
    return(`attr<-`(character(0), "bridge_fail", "unknown-path"))
  }
  args <- if (identical(op, "nav")) list(
    path = as.character(query$path %||% ""),
    line = suppressWarnings(as.integer(query$line %||% 1))
  ) else list()
  .dairh_bridge_call(op, args)
}

# \u6865\u72B6\u6001\u63A2\u9488\uFF08\u5B50\u8FDB\u7A0B\u5185\u7528\uFF09\uFF1A\u8FD4\u56DE list(ok=, reason=, base=)
.dairh_bridge_probe <- function() {
  base <- .dairh_bridge_get("/base_dir")
  ok <- length(base) > 0 && nzchar(base)
  list(ok = ok, reason = attr(base, "bridge_fail") %||% "",
       base = if (ok) base else "")
}

# \u5B50\u8FDB\u7A0B\u8BFB\u6700\u65B0\u7F16\u8F91\u5668\u5FEB\u7167\uFF08\u5FEB\u7167\u5F0F\u67B6\u6784\u7684\u4E3B\u901A\u9053\uFF09\uFF1A
# \u8FD4\u56DE list(time=, base_dir=, context=) \u6216 NULL\uFF08\u5C1A\u65E0\u5FEB\u7167\uFF09\u3002
.dairh_bridge_snapshot <- function() {
  dir <- getOption("daiRH.bridge_dir") %||% ""
  if (!nzchar(dir)) return(NULL)
  f <- file.path(dir, "context-snapshot.json")
  if (!file.exists(f)) return(NULL)
  tryCatch(
    jsonlite::fromJSON(f, simplifyVector = FALSE),
    error = function(e) NULL
  )
}

# ---- \u540E\u53F0\u542F\u52A8\u5668 --------------------------------------------------------------

# \u5B50\u8FDB\u7A0B\u65E5\u5FD7\u6587\u4EF6\uFF08stdout/stderr \u5404\u4E00\u4EFD\uFF0C\u843D\u5728\u7528\u6237\u7F13\u5B58\u76EE\u5F55\uFF0C
# \u65B9\u4FBF\u542F\u52A8\u540E\u518D\u53D1\u751F\u7684\u9519\u8BEF\uFF08\u4F8B\u5982\u4F1A\u8BDD\u5EFA\u7ACB\u65F6\u62A5\u9519\uFF09\u4E8B\u540E\u6392\u67E5\uFF09
.dairh_new_logfiles <- function() {
  dir <- tryCatch(file.path(tools::R_user_dir("daiRH", "cache"), "panel-logs"),
    error = function(e) tempfile(pattern = "daiRH-logs-")
  )
  dir.create(dir, recursive = TRUE, showWarnings = FALSE)
  tag <- format(Sys.time(), "%Y%m%d-%H%M%S")
  list(
    stdout = file.path(dir, sprintf("panel-%s.out.log", tag)),
    stderr = file.path(dir, sprintf("panel-%s.err.log", tag)),
    dir = dir
  )
}

.dairh_wait_app_ready <- function(port, timeout_s = 15) {
  url <- sprintf("http://127.0.0.1:%d", port)
  t0 <- Sys.time()
  while (difftime(Sys.time(), t0, units = "secs") < timeout_s) {
    up <- tryCatch(
      {
        resp <- httr2::request(url) |>
          httr2::req_timeout(1) |>
          httr2::req_perform()
        httr2::resp_status(resp) == 200L
      },
      error = function(e) FALSE
    )
    if (isTRUE(up)) return(TRUE)
    Sys.sleep(0.4)
  }
  FALSE
}

# \u540E\u53F0\u6A21\u5F0F\u542F\u52A8\uFF08addin \u5185\u90E8\u8C03\u7528\uFF09
.dairh_chat_launch_bg <- function(cfg) {
  t0 <- Sys.time()
  # \u7ACB\u523B\u7ED9\u53CD\u9988\uFF1A\u5C31\u7EEA\u7B49\u5F85\u6700\u957F 15 \u79D2\uFF0C\u9759\u9ED8\u7B49\u4F1A\u88AB\u8BEF\u89E3\u4E3A"\u70B9\u4E86\u6CA1\u53CD\u5E94"
  message("DaiRH \u6B63\u5728\u540E\u53F0\u542F\u52A8\u65B0\u9762\u677F\uFF08\u9009\u7AEF\u53E3 \u2192 \u8D77\u5B50\u8FDB\u7A0B \u2192 \u7B49\u5C31\u7EEA\uFF0C\u4E00\u822C 3~15 \u79D2\uFF09\u2026\u2026")
  bridge_dir <- dairh_bridge_start()
  bridge_url <- if (is.character(bridge_dir) && nzchar(bridge_dir)) bridge_dir else ""
  port <- .dairh_free_port()
  base_dir <- dairh_base_dir()
  logs <- .dairh_new_logfiles()
  # \u542F\u52A8\u65F6\u5728\u4E3B\u4F1A\u8BDD\u6293\u4E00\u4EFD\u7F16\u8F91\u5668\u4E0A\u4E0B\u6587\u5FEB\u7167\uFF1A\u5199\u6210\u5FEB\u7167\u6587\u4EF6\uFF08\u5FEB\u7167\u5F0F\u67B6\u6784\uFF09\uFF0C
  # \u4E4B\u540E\u7531\u6CF5\u5728\u6BCF\u6B21\u63A7\u5236\u53F0\u6D3B\u52A8\u8FB9\u754C\u5237\u65B0\u3002\u6865\u5931\u8054\u65F6\u5DE5\u5177\u56DE\u9000\u7528\u3002
  editor_snapshot <- tryCatch(dairh_editor_context_text(), error = function(e) "")
  snapshot_base <- base_dir
  if (is.character(bridge_dir) && nzchar(bridge_dir)) {
    tryCatch(
      writeLines(
        jsonlite::toJSON(
          list(time = format(Sys.time(), "%H:%M:%S"),
               base_dir = base_dir, context = editor_snapshot),
          auto_unbox = TRUE, null = "null"
        ),
        file.path(bridge_dir, "context-snapshot.json"), useBytes = TRUE
      ),
      error = function(e) NULL
    )
  }

  child <- callr::r_bg(
    function(port, cfg, bridge_dir, base_dir, editor_snapshot, snapshot_base) {
      library(daiRH)
      options(
        daiRH.bridge_dir = bridge_dir,
        daiRH.daemon_mode = TRUE,
        daiRH.editor_snapshot = editor_snapshot,
        daiRH.snapshot_base = snapshot_base
      )
      setwd(base_dir)
      app <- dairh_app(cfg)
      # \u6700\u540E\u4E00\u4E2A\u9875\u9762\u5173\u95ED\u540E\u81EA\u52A8\u9000\u51FA\uFF083 \u79D2\u5BBD\u9650\uFF0C\u9875\u9762\u5237\u65B0/\u91CD\u8FDE\u65F6\u4E0D\u4F1A\u8BEF\u505C\uFF09\uFF1B
      # \u5B50\u8FDB\u7A0B\u7684 R \u662F callr \u4F1A\u8BDD\uFF0CrunApp \u8FD4\u56DE\u540E\u4E0D\u4F1A\u81EA\u5DF1\u9000\u51FA\uFF0C\u9700\u663E\u5F0F quit\u3002
      n_act <- new.env(); n_act$active <- 0L
      server_wrapped <- function(input, output, session) {
        n_act$active <- n_act$active + 1L
        session$onSessionEnded(function() {
          n_act$active <- max(0L, n_act$active - 1L)
          stop_later <- function() {
            if (n_act$active <= 0L) shiny::stopApp()
          }
          if (requireNamespace("later", quietly = TRUE)) {
            later::later(stop_later, 3)
          } else {
            stop_later()
          }
        })
        app$server(input, output, session)
      }
      shiny::runApp(
        list(ui = app$ui, server = server_wrapped),
        port = port, launch.browser = FALSE
      )
      quit(save = "no", status = 0)
    },
    args = list(
      port = port, cfg = cfg, bridge_dir = bridge_dir, base_dir = base_dir,
      editor_snapshot = editor_snapshot, snapshot_base = snapshot_base
    ),
    stdout = logs$stdout,
    stderr = logs$stderr,
    supervise = TRUE
  )
  # \u5F3A\u5F15\u7528\u4FDD\u6301 job \u5B58\u6D3B\uFF08\u89C1 .dairh_bg_children \u6CE8\u91CA\uFF09
  idx <- length(.dairh_bg_children$childs) + 1L
  .dairh_bg_children$childs[[idx]] <- child
  .dairh_bg_children$last_port <- port

  # pid \u767B\u8BB0\u6587\u4EF6\uFF1A\u63A7\u5236\u53F0 Restart R \u540E\u53E5\u67C4\u5168\u90E8\u5931\u6548\uFF0C
  # \u4EC5\u9760 dairh_panel_stop() \u7684 dairh_bg_children$childs \u53E5\u67C4\u6740\u4E0D\u5230\u8DE8\u4F1A\u8BDD\u7684\u5B64\u513F\u3002
  # \u767B\u8BB0 <pid> + \u542F\u52A8\u65F6\u523B\uFF0C\u5B64\u513F\u56DE\u6536\uFF08.dairh_sweep_orphan_children\uFF09\u65F6\u7528\u3002
  pid_file <- paste0(logs$stdout, ".pid")
  tryCatch(
    writeLines(as.character(child$get_pid()), pid_file),
    error = function(e) NULL
  )
  attr(child, "dairh_pid_file") <- pid_file

  ready <- .dairh_wait_app_ready(port)
  url <- sprintf("http://127.0.0.1:%d", port)
  if (!ready && !child$is_alive()) {
    # \u5B50\u8FDB\u7A0B\u6B7B\u4E86\uFF1A\u767B\u8BB0\u6587\u4EF6\u6CA1\u7528\uFF0C\u9760\u56DE\u6536\u4F1A\u665A\u4E00\u62CD\uFF0C\u88AB\u6B7B\u76F4\u63A5\u6E05
    tryCatch(file.remove(pid_file), error = function(e) NULL)
    out <- tryCatch(if (file.exists(logs$stderr)) {
      paste(readLines(logs$stderr, warn = FALSE), collapse = "")
    } else "\uFF08\u65E0\u8F93\u51FA\uFF09",
      error = function(e) "\uFF08\u65E0\u8F93\u51FA\uFF09")
    stop("DaiRH \u540E\u53F0\u9762\u677F\u542F\u52A8\u5931\u8D25\uFF1A", .dai_clip(out, 1200), call. = FALSE)
  }
  if (!ready) {
    stop("DaiRH \u540E\u53F0\u9762\u677F 15 \u79D2\u5185\u672A\u5C31\u7EEA\uFF0C\u8BF7\u91CD\u8BD5\u3002",
      "\u65E5\u5FD7\uFF1A", logs$stderr, call. = FALSE)
  }

  # \u5B50\u8FDB\u7A0B stderr \u6301\u7EED\u955C\u50CF\u5230\u63A7\u5236\u53F0\uFF1A\u4F1A\u8BDD\u5EFA\u7ACB\u4EE5\u540E\u7684\u62A5\u9519\u4E5F\u80FD\u7B2C\u4E00\u65F6\u95F4\u770B\u5230
  .dairh_start_err_mirror(child, logs$stderr)

  if (!isTRUE(getOption("daiRH.no_viewer"))) {
    .dairh_open_viewer(url)
  }

  message(
    "DaiRH \u540E\u53F0\u9762\u677F\u5DF2\u542F\u52A8\uFF08\u7528\u65F6 ",
    format(round(as.numeric(difftime(Sys.time(), t0, units = "secs")), 1),
      nsmall = 1),
    " \u79D2\uFF09\uFF1A", url, "\n",
    "\u63A7\u5236\u53F0\u5DF2\u7A7A\u95F2\uFF0C\u53EF\u7EE7\u7EED\u6B63\u5E38\u4F7F\u7528\u3002\u5173\u95ED\u9762\u677F\u6807\u7B7E\u9875\u5373\u53EF\u7ED3\u675F\u672C\u6B21\u4F1A\u8BDD\u3002",
    "\n\u9762\u677F\u65E5\u5FD7\uFF08\u6392\u67E5\u7528\uFF09\uFF1A", logs$dir,
    if (!nzchar(bridge_url)) "\n\u26A0 \u672A\u5EFA\u7ACB RStudio \u80FD\u529B\u6865\uFF1A\u7F16\u8F91\u5668\u4E0A\u4E0B\u6587\u5C06\u4F7F\u7528\u542F\u52A8\u65F6\u5FEB\u7167\uFF0C\u8DF3\u8F6C\u4E0D\u53EF\u7528"
  )
  invisible(child)
}

# \u628A\u5B50\u8FDB\u7A0B stderr \u7684\u65B0\u589E\u5185\u5BB9\u5E42\u955C\u5230\u63A7\u5236\u53F0\u3002
# \u6CE8\u610F\uFF1A\u8BA1\u6570\u5668\u5FC5\u987B\u653E\u5728\u672C\u6B21\u5E42\u955C\u72EC\u7ACB\u7684 state \u73AF\u5883\u91CC\uFF01
# \u66FE\u628A\u5B83\u653E\u8FDB\u5305\u7EA7 .dairh_bg_children \uFF0C\u591A\u9762\u677F\u5B9E\u4F8B\u4E92\u76F8\u628A\u5BF9\u65B9\u7684
# \u9000\u51FA\u8BA1\u6570\u91CD\u7F6E\u5F52\u96F6\uFF0C\u5BFC\u81F4"\u5B50\u8FDB\u7A0B\u5DF2\u9000\u51FA"\u65E0\u9650\u5237\u5C4F\u3002
# \u786C\u4E0A\u9650\uFF1A\u9000\u51FA\u540E\u518D\u6253 dead_patience \u671F\u5FC5\u505C\uFF1B\u8FD0\u884C\u4E2D\u4E5F\u6709\u603B tick \u4E0A\u9650\u3002
.dairh_start_err_mirror <- function(child, err_file, interval = 2,
                                     dead_patience = 10, max_ticks = 300) {
  if (!requireNamespace("later", quietly = TRUE)) return(invisible(NULL))
  state <- new.env(parent = emptyenv())
  state$last_n <- 0L
  state$dead_n <- 0L
  state$announce_exit <- TRUE
  state$stop_flag <- FALSE
  ticks_left <- max_ticks
  lst <- .dairh_bg_children$mirrors
  idx <- length(lst) + 1L
  lst[[idx]] <- state
  .dairh_bg_children$mirrors <- lst
  step <- function() {
    if (isTRUE(state$stop_flag)) return(invisible(NULL))
    ticks_left <<- ticks_left - 1L
    alive <- tryCatch(isTRUE(child$is_alive()), error = function(e) FALSE)
    txt <- tryCatch(
      if (file.exists(err_file)) {
        paste(readLines(err_file, warn = FALSE), collapse = "\n")
      } else "",
      error = function(e) ""
    )
    last <- state$last_n
    n <- nchar(txt)
    if (n > last) {
      state$last_n <- n
      # \u5E26\u65F6\u95F4\u6233\uFF1A\u955C\u50CF\u6D88\u606F\u5E38\u5728\u63A7\u5236\u53F0\u5FD9\u5B8C\u540E\u624D\u51FA\u73B0\uFF0C
      # \u4E0D\u6807\u65F6\u95F4\u4F1A\u88AB\u8BEF\u8BA4\u4E3A\u662F"\u521A\u53D1\u751F"\u7684\u4E8B\u60C5
      message(
        "[", format(Sys.time(), "%H:%M:%S"),
        "] DaiRH \u9762\u677F\u5B50\u8FDB\u7A0B stderr \u65B0\u5185\u5BB9\uFF1A\n",
        .dai_clip(substr(txt, last + 1L, n), 3000)
      )
    }
    if (alive) {
      state$dead_n <- 0L
      if (ticks_left > 0L) later::later(step, interval)
    } else {
      state$dead_n <- state$dead_n + 1L
      if (isTRUE(state$announce_exit)) {
        state$announce_exit <- FALSE
        message(
          "[", format(Sys.time(), "%H:%M:%S"),
          "] DaiRH \u9762\u677F\u5B50\u8FDB\u7A0B\u5DF2\u9000\u51FA\uFF1B\u5B8C\u6574\u65E5\u5FD7\uFF1A",
          .dairh_log_hint(err_file),
          "\n\uFF08\u91CD\u65B0\u6253\u5F00\uFF1A\u63A7\u5236\u53F0\u8FD0\u884C daiRH::dairh_panel_restart() \u53EF\u6362\u53D1\u5168\u65B0\u4F1A\u8BDD\u9762\u677F\uFF09"
        )
      }
      if (state$dead_n < dead_patience && ticks_left > 0L) {
        later::later(step, 1.5)
      }
    }
  }
  later::later(step, interval)
  invisible(state)
}

.dairh_log_hint <- function(err_file) {
  if (.dairh_rstudio_available()) {
    tryCatch(rstudioapi::navigateToFile(err_file), error = function(e) NULL)
    return("")
  }
  dirname(err_file)
}

# \u6253\u5F00\u5230 RStudio \u7684 Viewer \u9762\u677F\uFF08\u4E0D\u5728 RStudio \u65F6\u7528\u7CFB\u7EDF\u6D4F\u89C8\u5668\uFF09
.dairh_open_viewer <- function(url) {
  shown <- FALSE
  if (.dairh_rstudio_available()) {
    shown <- tryCatch(
      {
        rstudioapi::viewer(url)
        TRUE
      },
      error = function(e) FALSE
    )
  }
  if (!isTRUE(shown)) {
    shown <- tryCatch(
      {
        utils::browseURL(url)
        TRUE
      },
      error = function(e) FALSE
    )
  }
  invisible(shown)
}

# ---- \u5B64\u513F\u9762\u677F\u5B50\u8FDB\u7A0B\u56DE\u6536 ----------------------------------------------------
# \u573A\u666F\uFF1A\u63A7\u5236\u53F0 Restart R\uFF08\u88C5\u5305\u56DE\u6765\u540E\u5FC5\u7ECF\uFF09\u4E4B\u540E\u53E5\u67C4\u5168\u5931\u6548\uFF0C
# \u8D77\u524D\u9762\u677F\u7684\u5B50\u8FDB\u7A0B\u8FD8\u6D3B\u7740\uFF0Cdairh_panel_stop() \u6740\u4E0D\u5230\u3002
# \u5B9E\u73B0\uFF1A\u6BCF\u6B21\u542F\u52A8\u9762\u677F\u65F6\u5728 panel-logs \u76EE\u5F55\u767B\u8BB0 <pid> \u6587\u4EF6\uFF08\u89C1
# .dairh_chat_launch_bg\uFF09\uFF1B\u505C\u624B\u65F6\u626B\u63CF\u767B\u8BB0\uFF0C\u547D\u4EE4\u884C\u5E26 callr
# \u4E34\u65F6\u811A\u672C\u6807\u8BB0\u7684 R \u8FDB\u7A0B\u624D\u52A8\u5200\uFF08\u4E0D\u8BEF\u6740 pid \u590D\u7528\u540E\u7684\u65E0\u5173\u8FDB\u7A0B\uFF09\uFF1B
# \u8BFB\u4E0D\u5230\u547D\u4EE4\u884C\uFF08\u6743\u9650\u4E0D\u591F\uFF09\u65F6\u4E0D\u6740\uFF0C\u767B\u8BB0\u6539\u540D .stale\uFF0C\u518D\u9047\u5373\u6E05\uFF1B
# \u767B\u8BB0\u6587\u4EF6\u8D85 1 \u5929\u81EA\u52A8\u8FC7\u671F\u6E05\u7406\u3002

.dairh_pid_dir <- function() {
  d <- getOption("daiRH.pid_dir")
  if (is.null(d) || !is.character(d) || !nzchar(d)) {
    d <- tryCatch(
      file.path(tools::R_user_dir("daiRH", "cache"), "panel-logs"),
      error = function(e) NULL
    )
  }
  if (is.null(d)) return(NULL)
  dir.create(d, recursive = TRUE, showWarnings = FALSE)
  d
}

.dairh_sweep_orphan_children <- function(skip_pids = integer(0L)) {
  dir <- .dairh_pid_dir()
  if (is.null(dir) || !dir.exists(dir)) return(0L)
  files <- list.files(dir, pattern = "\\.pid(\\.stale)?$", full.names = TRUE)
  if (!length(files) || !requireNamespace("ps", quietly = TRUE)) return(0L)
  killed <- 0L
  for (f in files) {
    mt <- tryCatch(file.info(f)$mtime, error = function(e) NA)
    if (is.na(mt) || difftime(Sys.time(), mt, units = "days") > 1) {
      unlink(f)
      next
    }
    rec <- tryCatch(readLines(f, warn = FALSE), error = function(e) NULL)
    pid <- suppressWarnings(
      as.integer(strsplit(paste(rec[[1]], collapse = " "), " ",
        fixed = TRUE)[[1]][[1]])
    )
    if (is.na(pid) || pid <= 0L) {
      unlink(f)
      next
    }
    if (pid %in% skip_pids) next
    verdict <- tryCatch({
      cl <- paste(ps::ps_cmdline(ps::ps_handle(pid)), collapse = " ")
      if (grepl("callr-scr-", cl, fixed = TRUE)) "kill" else "reuse"
    }, error = function(e) "noprobe")
    if (identical(verdict, "kill")) {
      tryCatch(tools::pskill(pid), error = function(e) NULL)
      unlink(f)
      killed <- killed + 1L
    } else if (identical(verdict, "reuse")) {
      # pid \u5DF2\u88AB\u5176\u4ED6\u8FDB\u7A0B\u590D\u7528\uFF08\u6307\u7EB9\u4E0D\u7B26\uFF09\uFF1A\u53EA\u6E05\u767B\u8BB0\uFF0C\u4E0D\u6740
      unlink(f)
    } else if (grepl("\\.stale$", f)) {
      # \u4E0A\u4E00\u8F6E\u5DF2\u6807 stale \u8FD8\u6838\u4E0D\u4E86 \u2192 \u76F4\u63A5\u4E22\uFF0C\u4E0D\u518D\u9644\u52A0 .stale \u7D2F\u79EF
      unlink(f)
    } else {
      # \u6838\u4E0D\u4E86\u6307\u7EB9\uFF08\u6743\u9650\u4E0D\u591F\uFF09\uFF1A\u540D\u5B57\u6539 .stale\uFF0C\u4E0B\u4E00\u8F6E\u76F4\u63A5\u6E05\uFF0C\u4E0D\u5192\u6740\u98CE\u9669
      tryCatch(file.rename(f, paste0(f, ".stale")), error = function(e) NULL)
    }
  }
  killed
}

#' \u5173\u95ED\u540E\u53F0\u8FD0\u884C\u7684 DaiRH \u9762\u677F
#'
#' \u6740\u6389\u540E\u53F0\u6A21\u5F0F\u542F\u52A8\u7684\u6240\u6709\u9762\u677F\u5B50\u8FDB\u7A0B\uFF0C\u5E76\u505C\u6389\u4E3B\u4F1A\u8BDD\u5185\u7684
#' RStudio \u80FD\u529B\u6865\u3002\u4E00\u822C\u76F4\u63A5\u5173\u6389\u9762\u677F\u6807\u7B7E\u9875\u5C31\u591F\u4E86\uFF08\u6700\u540E\u4E00\u4E2A
#' \u9875\u9762\u5173\u95ED\u540E\u5B50\u8FDB\u7A0B\u5728\u6570\u79D2\u5BBD\u9650\u5185\u81EA\u52A8\u9000\u51FA\uFF09\uFF1B\u8FD9\u4E2A\u51FD\u6570\u7528\u4E8E
#' \u4E8B\u540E\u6E05\u7406\u6B8B\u7559\u8FDB\u7A0B\u6216\u5F3A\u5236\u7ED3\u675F\u4F1A\u8BDD\u3002\u63A7\u5236\u53F0 Restart R \u540E\u53E5\u67C4
#' \u5931\u6548\u65F6\uFF0C\u672C\u51FD\u6570\u8FD8\u4F1A\u6309\u542F\u52A8\u65F6\u7684 pid \u767B\u8BB0\u6587\u4EF6\u626B\u63CF\u56DE\u6536\u8DE8\u4F1A\u8BDD\u5B64\u513F
#' \u9762\u677F\u5B50\u8FDB\u7A0B\uFF08\u4EC5\u6740\u547D\u4EE4\u884C\u5E26 callr \u811A\u672C\u6807\u8BB0\u7684 R \u8FDB\u7A0B\uFF0C\u4E0D\u8BEF\u4F24\u5176\u5B83\u8FDB\u7A0B\uFF09\u3002
#' \u7ECF\u5178\u6A21\u5F0F\uFF08gadget\uFF09\u65E0\u9700\u8C03\u7528\u3002
#'
#' @return \u9690\u5F0F\u8FD4\u56DE\u65E0\u503C
#' @examples
#' \dontrun{
#' dairh_panel_stop()
#' }
#' @export
dairh_panel_stop <- function() {
  chs <- .dairh_bg_children$childs
  n <- 0L
  reg_pids <- integer(0L)
  for (ch in chs) {
    pid <- tryCatch(as.integer(ch$get_pid()), error = function(e) NA_integer_)
    alive <- tryCatch(isTRUE(ch$is_alive()), error = function(e) FALSE)
    if (alive) {
      tryCatch(ch$kill(), error = function(e) NULL)
      n <- n + 1L
    }
    if (!is.null(pid) && !is.na(pid) && pid > 0L) reg_pids <- c(reg_pids, pid)
    # \u767B\u8BB0\u6587\u4EF6\u5C31\u5730\u6E05\uFF1A\u6B63\u5E38\u6740\u63C9/\u5DF2\u9000\u51FA\u90FD\u4E0D\u8BE5\u9057\u7ED9\u5B64\u513F\u626B\u63CF
    pf <- attr(ch, "dairh_pid_file")
    if (!is.null(pf)) tryCatch(file.remove(pf), error = function(e) NULL)
  }
  .dairh_bg_children$childs <- list()
  # \u505C\u6389\u6240\u6709 stderr \u955C\u50CF\u5FAA\u73AF\uFF08\u907F\u514D\u5B83\u4EEC\u518D\u5BF9\u7740\u6B7B\u8FDB\u7A0B\u6253\u8F6C\uFF09
  for (m in .dairh_bg_children$mirrors) {
    tryCatch(m$stop_flag <- TRUE, error = function(e) NULL)
  }
  .dairh_bg_children$mirrors <- list()
  n_orph <- .dairh_sweep_orphan_children(reg_pids)
  .dairh_bridge_stop()
  if (n > 0L && n_orph > 0L) {
    message("\u5DF2\u505C\u6B62\u6240\u6709\u540E\u53F0 DaiRH \u9762\u677F\uFF08", n,
      " \u4E2A\u5B50\u8FDB\u7A0B\uFF09\uFF0C\u53E6\u56DE\u6536 ", n_orph,
      " \u4E2A\u8DE8\u4F1A\u8BDD\u5B64\u513F\u9762\u677F\u3002")
  } else if (n > 0L) {
    message("\u5DF2\u505C\u6B62\u6240\u6709\u540E\u53F0 DaiRH \u9762\u677F\uFF08", n, " \u4E2A\u5B50\u8FDB\u7A0B\uFF09\u3002")
  } else if (n_orph > 0L) {
    message("\u672C\u4F1A\u8BDD\u672A\u767B\u8BB0\u9762\u677F\uFF0C\u4F46\u56DE\u6536\u4E86 ", n_orph,
      " \u4E2A\u8DE8\u4F1A\u8BDD\u5B64\u513F\u9762\u677F\u5B50\u8FDB\u7A0B\u3002")
  } else {
    message("\u5F53\u524D\u6CA1\u6709\u8FD0\u884C\u4E2D\u7684\u540E\u53F0\u9762\u677F\u3002")
  }
  invisible(NULL)
}

#' \u91CD\u542F\u540E\u53F0\u8FD0\u884C\u7684 DaiRH \u9762\u677F
#'
#' \u505C\u6240\u6709\u9762\u677F\u5B50\u8FDB\u7A0B\uFF0C\u5E76\u6309\u5F53\u524D\u914D\u7F6E\u91CD\u65B0\u6253\u5F00\uFF08\u540E\u53F0\u6A21\u5F0F
#' \u4F1A\u81EA\u52A8\u91CD\u5F00 Viewer\uFF09\u3002\u7ED9\u9762\u677F\u957F\u65F6\u95F4\u4E0D\u54CD\u5E94\u3001\u5B50\u8FDB\u7A0B\u610F\u5916\u9000\u51FA\u6216
#' \u53EA\u60F3\u6362\u53D1\u5168\u65B0\u4F1A\u8BDD\u65F6\u7528\uFF0C\u76F8\u5F53\u4E8E"panel_stop + \u76F4\u63A5\u518D\u6253\u5F00"\u3002
#' \u5386\u53F2\u6D88\u606F\u4E0D\u540C\u5F00\u65B0\u9762\u677F\uFF08\u9762\u677F\u4E0D\u6301\u4E45\u5316\u804A\u8BB0\uFF09\u3002
#'
#' @return \u9690\u5F0F\u8FD4\u56DE\u65B0\u542F\u52A8\u7684\u9762\u677F\u5B50\u8FDB\u7A0B\u53E5\u67B0
#' @examples
#' \dontrun{
#' dairh_panel_restart()
#' }
#' @export
dairh_panel_restart <- function() {
  dairh_panel_stop()
  dairh_addin_chat()
}

#' \u81EA\u68C0\u7F16\u8F91\u5668\u4E0A\u4E0B\u6587\u5FEB\u7167\uFF08\u8BCA\u65AD\u7528\uFF09
#'
#' \u62A5\u544A\u5FEB\u7167\u6587\u4EF6\u7684\u72B6\u6001\uFF1A\u662F\u5426\u5B58\u5728\u3001\u5FEB\u7167\u65F6\u95F4\u3001
#' \u5F53\u65F6\u662F\u5426\u6709\u5DF2\u4FDD\u5B58\u7684\u6D3B\u52A8\u6587\u4EF6\u3002\u9762\u677F\u540E\u53F0\u6A21\u5F0F\u62FF\u4E0D\u5230
#' \u7F16\u8F91\u5668\u5185\u5BB9\u65F6\uFF0C\u7528\u5B83\u5224\u65AD\u5FEB\u7167\u94FE\u8DEF\u7684\u5065\u5EB7\u72B6\u6001\u3002
#'
#' @return \u547D\u540D\u5217\u8868\uFF1adir / snapshot_time / base_dir / context_chars
#' @examples
#' \dontrun{
#' daiRH::dairh_bridge_test()
#' }
#' @export
dairh_bridge_test <- function() {
  dir <- .dairh_bridge_env$dir
  j <- if (!is.null(dir) && nzchar(dir)) .dairh_bridge_snapshot() else NULL
  list(
    dir = dir,
    snapshot_time = as.character(j$time %||% ""),
    base_dir = as.character(j$base_dir %||% ""),
    context_chars = nchar(as.character(j$context %||% ""))
  )
}

.dairh_bridge_stop <- function() {
  .dairh_bridge_env$pumping <- FALSE
  .dairh_bridge_env$dir <- NULL
  invisible(NULL)
}
