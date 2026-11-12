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
#' \u672A\u4FDD\u5B58\u7684\u65E0\u6807\u9898\u6587\u6863\u540C\u6837\u652F\u6301\uFF08\u76F4\u63A5\u8BFB\u5185\u5B58\u5185\u5BB9\uFF09\uFF1B\u4E0D\u5728 RStudio \u4E2D\u65F6\u8FD4\u56DE\u63D0\u793A\u6587\u672C\u3002
#'
#' @param max_lines \u6587\u4EF6\u5185\u5BB9\u6700\u591A\u6CE8\u5165\u7684\u884C\u6570
#' @return \u5355\u4E2A\u5B57\u7B26\u4E32\uFF08markdown/\u7EAF\u6587\u672C\u5757\uFF09
#' @export
dairh_editor_context_text <- function(max_lines = 160) {
  if (!.dairh_rstudio_available()) {
    return("\u5F53\u524D\u4E0D\u5728 RStudio \u4E2D\uFF0C\u65E0\u6CD5\u8BFB\u53D6\u6D3B\u52A8\u7F16\u8F91\u5668\u4E0A\u4E0B\u6587\u3002")
  }
  # \u4F18\u5148\u6E90\u7F16\u8F91\u5668\u7A97\u683C\uFF1AgetActiveDocumentContext \u5728\u63A7\u5236\u53F0\u6301\u7126\u65F6\u8BED\u4E49\u542B\u7CCA\uFF0C
  # "\u5F53\u524D\u6587\u4EF6"\u5BF9\u7528\u6237\u800C\u8A00\u6C38\u8FDC\u662F\u6E90\u7801\u7A97\u683C\u91CC\u90A3\u4E2A\u6807\u7B7E\u9875
  ctx <- tryCatch(rstudioapi::getSourceEditorContext(), error = function(e) NULL)
  if (is.null(ctx)) {
    ctx <- tryCatch(rstudioapi::getActiveDocumentContext(), error = function(e) NULL)
  }
  if (is.null(ctx)) {
    return("\u5F53\u524D\u65E0\u6CD5\u8BFB\u53D6 RStudio \u6D3B\u52A8\u7F16\u8F91\u5668\u4E0A\u4E0B\u6587\u3002")
  }
  .dairh_format_editor_ctx(ctx, max_lines = max_lines)
}

# \u7EAF\u683C\u5F0F\u5316\uFF08\u53EF\u5355\u6D4B\uFF09\uFF1Actx \u4E3A rstudioapi \u6587\u6863\u4E0A\u4E0B\u6587\u5F62\u72B6\u7684\u5217\u8868\u3002
# \u5173\u952E\u70B9\uFF1A\u672A\u4FDD\u5B58\u6587\u6863\uFF08path \u4E3A\u7A7A\uFF09\u4E0D\u518D\u88AB\u6321\u2014\u2014contents/\u9009\u533A\u5728\u5185\u5B58\u91CC\u5C31\u6709\uFF1B
# \u9009\u533A\u884C\u53F7\u5FC5\u987B\u7528 range$start$row\uFF08rstudioapi \u5B57\u6BB5\u540D\uFF1B\u6B64\u524D\u8BEF\u5199 $rE\uFF0C
# pmatch \u4E0D\u4E2D\u6052\u4E3A NULL\uFF0C\u9009\u533A\u5757\u9759\u9ED8\u84B8\u53D1\uFF0C\u6A21\u578B\u6C38\u8FDC"\u770B\u4E0D\u5230\u9009\u533A"\uFF09\u3002
.dairh_format_editor_ctx <- function(ctx, max_lines = 160) {
  contents <- ctx$contents %||% ""
  has_path <- nzchar(ctx$path %||% "")
  if (!has_path && !nzchar(contents)) {
    return("\u5F53\u524D\u6CA1\u6709\u53EF\u8BFB\u53D6\u7684\u6D3B\u52A8\u6587\u6863\u5185\u5BB9\u3002")
  }
  path_lab <- if (has_path) ctx$path else
    "\uFF08\u672A\u4FDD\u5B58\u7684\u65E0\u6807\u9898\u6587\u6863\uFF1B\u5185\u5BB9\u5982\u4E0B\uFF0C\u4FDD\u5B58\u540E Agent \u53EF\u7528 read_file \u8DDF\u8FDB\uFF09"
  lines <- strsplit(contents, "\n", fixed = TRUE)[[1]] %||% character(0)
  n <- length(lines)
  show_n <- min(n, max_lines)
  out <- c(
    sprintf("\u3010\u6D3B\u52A8\u6587\u4EF6\u3011%s\uFF08\u5171 %d \u884C\uFF09", path_lab, n),
    "\u5185\u5BB9\uFF1A",
    .dai_numbered(lines[seq_len(show_n)], 1L)
  )
  if (show_n < n) {
    out <- c(out, sprintf(
      "...\uFF08\u5171 %d \u884C\uFF0C\u4EC5\u663E\u793A\u524D %d \u884C\uFF0C\u53EF\u7528 read_file \u7EE7\u7EED\u8BFB\u53D6\u5176\u4F59\u90E8\u5206\uFF09", n, max_lines
    ))
  }

  sel <- tryCatch(rstudioapi::primary_selection(ctx), error = function(e) NULL)
  if (is.null(sel)) {
    # \u56DE\u9000\uFF1A\u63A5\u53D7\u7EAF\u5217\u8868\u5F62\u72B6\u7684 ctx\uFF08primary_selection \u662F S3 \u6CDB\u578B\uFF0C\u53EA\u8BA4
    # document_context \u7C7B\uFF1B\u771F\u5B9E\u5FEB\u7167\u8D70\u4E0A\u9762\uFF0C\u6865/\u6D4B\u8BD5\u5047\u4E0A\u4E0B\u6587\u8D70\u8FD9\u91CC\uFF09
    sel <- tryCatch(ctx$selection[[1]], error = function(e) NULL)
  }
  if (!is.null(sel) && !is.null(sel$text) && nzchar(sel$text)) {
    s <- .dairh_pos_row(sel$range$start, 1L)
    e <- .dairh_pos_row(sel$range$end, s)
    out <- c(
      out,
      sprintf("\u3010\u5F53\u524D\u9009\u533A\u3011\u7B2C %d\u2013%d \u884C\uFF1A", s, e),
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

# ---- 0.8 \u9879\u76EE\u6982\u89C8\uFF08\u4F1A\u8BDD\u542F\u52A8\u5FEB\u7167\uFF0C\u8FDB\u7CFB\u7EDF\u63D0\u793A\uFF09 --------------------------------
# \u53EA\u8BFB\u4FE1\u606F\u3001\u4EFB\u4F55\u5B50\u9879\u5931\u8D25\u9759\u9ED8\u964D\u7EA7\uFF1Agit \u5FEB\u7167\uFF08system2\uFF0C\u96F6\u65B0\u4F9D\u8D56\uFF09+ \u76EE\u5F55\u6811\u4E24\u5C42 +
# \u5DE5\u4F5C\u533A\u6458\u8981\uFF08\u6865\u63A5\u4F18\u5148 /workspace \u7AEF\u70B9\uFF0C\u56DE\u9000\u672C\u5730 globalenv\u2014\u2014\u4E0E workspace_summary
# \u5DE5\u5177\u540C\u6A21\u5F0F\uFF09\u3002\u9762\u677F\u5B50\u8FDB\u7A0B cwd \u5DF2\u662F\u9879\u76EE\u76EE\u5F55\uFF08background.R setwd\uFF09\uFF0Cgit -C \u53CC\u4FDD\u9669\u3002

.dairh_git_run <- function(args) {
  out <- tryCatch(
    suppressWarnings(system2("git", args, stdout = TRUE, stderr = FALSE, timeout = 5)),
    error = function(e) character(0)
  )
  st <- attr(out, "status")
  if (!is.null(st) && st != 0L) return(character(0))
  out <- trimws(as.character(out))
  out[nzchar(out)]
}

.dairh_brief_git <- function(base_dir) {
  pre <- c("-C", shQuote(base_dir))
  branch <- .dairh_git_run(c(pre, "rev-parse", "--abbrev-ref", "HEAD"))
  if (!length(branch)) return(character(0)) # \u65E0 git / \u975E\u4ED3\u5E93 / \u88F8\u4ED3\u5E93 \u2192 \u6574\u6BB5\u8DF3\u8FC7
  out <- sprintf("- git: \u5206\u652F %s", branch[[1]])
  head <- .dairh_git_run(c(pre, "log", "-1", "--oneline"))
  if (length(head)) out <- paste0(out, "\uFF0CHEAD ", head[[1]])
  st <- .dairh_git_run(c(pre, "status", "--porcelain"))
  if (length(st)) {
    out <- paste0(out, sprintf(
      "\uFF1B\u672A\u63D0\u4EA4\u53D8\u66F4 %s%s",
      paste(utils::head(st, 15), collapse = "\uFF1B"),
      if (length(st) > 15) sprintf("\u2026\uFF08\u5171 %d \u9879\uFF09", length(st)) else ""
    ))
  }
  out
}

.dairh_brief_tree <- function(base_dir) {
  ents <- tryCatch(
    list.files(base_dir, all.files = FALSE, no.. = TRUE),
    error = function(e) character(0)
  )
  if (!length(ents)) return(character(0))
  isdir <- file.info(file.path(base_dir, ents))$isdir
  isdir[is.na(isdir)] <- FALSE
  dirs <- ents[isdir]
  files <- ents[!isdir]
  out <- character(0)
  if (length(dirs)) {
    dd <- dirs[seq_len(min(length(dirs), 30L))]
    cnt <- vapply(dd, function(d) {
      length(list.files(file.path(base_dir, d), all.files = FALSE, no.. = TRUE))
    }, integer(1))
    txt <- paste(sprintf("%s(%d)", dd, cnt), collapse = "  ")
    if (length(dirs) > 30) txt <- paste0(txt, " \u2026\uFF08\u5171 ", length(dirs), " \u4E2A\u76EE\u5F55\uFF09")
    out <- c(out, paste0("- \u76EE\u5F55: ", txt))
  }
  if (length(files)) {
    ff <- paste(files[seq_len(min(length(files), 20L))], collapse = "  ")
    if (length(files) > 20) ff <- paste0(ff, " \u2026\uFF08\u5171 ", length(files), " \u4E2A\uFF09")
    out <- c(out, paste0("- \u9876\u5C42\u6587\u4EF6: ", ff))
  }
  out
}

.dairh_project_brief <- function(base_dir = dairh_base_dir(), include_workspace = TRUE) {
  base_dir <- tryCatch(normalizePath(base_dir, mustWork = FALSE),
                       error = function(e) base_dir)
  out <- character(0)
  out <- c(out, .dairh_brief_git(base_dir))
  out <- c(out, .dairh_brief_tree(base_dir))
  if (include_workspace) {
    ws <- tryCatch(.dairh_bridge_get("/workspace"), error = function(e) character(0))
    if (!length(ws) || !nzchar(ws)) {
      ws <- tryCatch(.dai_workspace_summary(), error = function(e) "")
    }
    # \u7A7A\u5DE5\u4F5C\u533A\u7684"\u6CA1\u6709\u5168\u5C40\u5BF9\u8C61"\u63D0\u793A\u5BF9\u6982\u89C8\u662F\u566A\u97F3\uFF0C\u8DF3\u8FC7
    if (length(ws) && nzchar(ws) && !grepl("\u6CA1\u6709\u5168\u5C40\u5BF9\u8C61", ws, fixed = TRUE)) {
      out <- c(out, paste0("- \u5DE5\u4F5C\u533A: ", ws))
    }
  }
  out
}
