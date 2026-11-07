# DaiRH Agent \u5DE5\u5177\u96C6 --------------------------------------------------------
# \u63D0\u4F9B\u7ED9 LLM \u7684\u5DE5\u5177\uFF1A\u8BFB/\u5217/\u5199/\u6539\u6587\u4EF6\u3001\u5B50\u8FDB\u7A0B\u8FD0\u884C R \u4EE3\u7801\u3001\u67E5 R \u6587\u6863\u3001
# \u5DE5\u4F5C\u533A\u6458\u8981\u3001\u7F16\u8F91\u5668\u4E0A\u4E0B\u6587\u3002
# \u5B89\u5168\u6A21\u578B\uFF1A
#   - \u6587\u4EF6\u5DE5\u5177\u9ED8\u8BA4\u9650\u5236\u5728 dairh_base_dir()\uFF08\u9879\u76EE/\u5DE5\u4F5C\u76EE\u5F55\uFF09\u5185\uFF08restrict_paths\uFF09
#   - run_r_code \u5728 callr \u5B50\u8FDB\u7A0B\u6267\u884C\uFF0C\u4E0D\u6C61\u67D3\u5F53\u524D\u4F1A\u8BDD\uFF0C\u5E26\u8D85\u65F6
#   - allow_edit / allow_run \u4E3A FALSE \u65F6\u4E0D\u6CE8\u518C\u5BF9\u5E94\u5DE5\u5177

# ---- \u8DEF\u5F84\u5B88\u536B --------------------------------------------------------------
.dai_path_guard <- function(path, base = dairh_base_dir(), restrict = TRUE) {
  if (!is.character(path) || length(path) != 1L || !nzchar(path) || is.na(path)) {
    stop("path \u5FC5\u987B\u662F\u975E\u7A7A\u5B57\u7B26\u4E32", call. = FALSE)
  }
  if (!grepl("^([A-Za-z]:[/\\\\]|[\\\\/]|~)", path)) {
    path <- file.path(base, path)
  }
  norm <- normalizePath(path, winslash = "/", mustWork = FALSE)
  if (!file.exists(norm)) {
    # \u4e0d\u5b58\u5728\u7684\u8def\u5f84\u5728 Windows/mac \u4e0a\u4e0d\u4f1a\u5c55\u5f00 8.3 \u77ed\u540d\uff08RUNNER~1\uff09
    # \u4e0e\u7b26\u53f7\u94fe\u63a5\uff08/var \u2192 /private/var\uff09\uff0c\u800c\u5df2\u5b58\u5728\u7684 base \u4f1a\u2014\u2014
    # \u524d\u7f00\u6bd4\u5bf9\u5fc5\u9519\u3002\u5148\u5f52\u4e00\u5316\u5df2\u5b58\u5728\u7684\u7236\u76ee\u5f55\u518d\u62fc\u53f6\u540d\u3002
    parent <- normalizePath(dirname(norm), winslash = "/", mustWork = FALSE)
    if (nzchar(parent)) {
      norm <- paste0(sub("/*$", "", parent), "/", basename(norm))
    }
  }
  if (restrict) {
    base_n <- normalizePath(base, winslash = "/", mustWork = FALSE)
    base_pre <- sub("/*$", "", base_n)
    if (!identical(norm, base_n) && !startsWith(norm, paste0(base_pre, "/"))) {
      stop(
        sprintf("\u51FA\u4E8E\u5B89\u5168\u8003\u8651\uFF0C\u6587\u4EF6\u64CD\u4F5C\u53EA\u5141\u8BB8\u5728 %s \u5185\u8FDB\u884C\uFF08\u53EF\u5728\u8BBE\u7F6E\u91CC\u5173\u95ED restrict_paths\uFF09\u3002", base_n),
        call. = FALSE
      )
    }
  }
  norm
}

# show_plot \u6821\u9A8C\u5668\uFF080.5 \u8D77\u56FE\u4E0D\u8FDB\u9762\u677F\u603B\u7EBF\uFF1A\u5DE5\u5177\u76F4\u63A5\u8FD4\u56DE Content \u5217\u8868\u8FDB\u5BF9\u8BDD\uFF0C
# shinychat 0.5 \u7684\u5DE5\u5177\u5361\u7247\u539F\u751F\u6E32\u67D3\uFF0C\u5386\u53F2\u91CD\u653E\u4E5F\u4E0D\u4E22\u2014\u2014\u603B\u7EBF/\u9759\u6001\u56FE\u76EE\u5F55\u5DF2\u9000\u5F79\uFF09\u3002
# \u8FD4\u56DE list(ok, msg)\uFF1Bok=TRUE \u65F6 msg \u4E3A\u7EDD\u5BF9\u8DEF\u5F84
.dai_show_plot_prep <- function(path, base, restrict) {
  p <- tryCatch(.dai_path_guard(path, base = base, restrict = restrict),
    error = function(e) NULL)
  if (is.null(p)) {
    return(list(ok = FALSE,
      msg = paste0("FAIL: \u8DEF\u5F84\u4E0D\u53EF\u7528\u6216\u8D85\u51FA\u9879\u76EE\u8303\u56F4: ", path)))
  }
  if (!file.exists(p)) {
    return(list(ok = FALSE, msg = paste0("FAIL: \u56FE\u7247\u4E0D\u5B58\u5728: ", p)))
  }
  ext <- tolower(tools::file_ext(p))
  kind <- switch(ext,
    png = "image/png", jpg = "image/jpeg", jpeg = "image/jpeg",
    webp = "image/webp", NULL
  )
  if (is.null(kind)) {
    return(list(ok = FALSE,
      msg = paste0("FAIL: \u4EC5\u652F\u6301 png/jpg/jpeg/webp\uFF0C\u5F53\u524D\u6269\u5C55\u540D: ",
        if (nzchar(ext)) ext else "\uFF08\u65E0\uFF09")))
  }
  size <- tryCatch(file.info(p)$size, error = function(e) NA_real_)
  if (!is.finite(size) || size <= 0) {
    return(list(ok = FALSE, msg = paste0("FAIL: \u56FE\u7247\u4E3A\u7A7A\u6216\u4E0D\u53EF\u8BFB: ", p)))
  }
  if (size > 4e6) {
    return(list(ok = FALSE, msg = paste0(
      "FAIL: \u56FE\u7247\u8FC7\u5927\uFF08", round(size / 1e6, 1),
      " MB > 4 MB\uFF09\u3002\u8BF7\u7528 png(..., width=, height=, res=) \u751F\u6210\u66F4\u5C0F\u7684\u56FE\u540E\u91CD\u8BD5\u3002")))
  }
  list(ok = TRUE, msg = p)
}

# show_html \u5DE5\u5177\u4F53\uFF1A\u6821\u9A8C\u540E\u7ECF\u80FD\u529B\u6865\u5728 RStudio Viewer \u6253\u5F00\uFF08leaflet/mapview \u7B49
# \u4EA4\u4E92\u5730\u56FE\u3001htmlwidgets \u8F93\u51FA\u7684\u6700\u8F7B\u901A\u9053\uFF09\uFF1B\u6865\u4E0D\u53EF\u7528\u9000\u7CFB\u7EDF\u6D4F\u89C8\u5668\u3002\u53EF\u5355\u6D4B\u3002
.dai_show_html <- function(path, base = dairh_base_dir(), restrict = TRUE) {
  p <- tryCatch(.dai_path_guard(path, base = base, restrict = restrict),
    error = function(e) NULL)
  if (is.null(p)) {
    return(paste0("FAIL: \u8DEF\u5F84\u4E0D\u53EF\u7528\u6216\u8D85\u51FA\u9879\u76EE\u8303\u56F4: ", path))
  }
  if (!file.exists(p)) return(paste0("FAIL: \u6587\u4EF6\u4E0D\u5B58\u5728: ", p))
  ext <- tolower(tools::file_ext(p))
  if (!identical(ext, "html") && !identical(ext, "htm")) {
    return(paste0("FAIL: \u4EC5\u652F\u6301 html/htm\uFF0C\u5F53\u524D\u6269\u5C55\u540D: ",
      if (nzchar(ext)) ext else "\uFF08\u65E0\uFF09"))
  }
  size <- tryCatch(file.info(p)$size, error = function(e) NA_real_)
  if (!is.finite(size) || size <= 0) {
    return(paste0("FAIL: \u6587\u4EF6\u4E3A\u7A7A\u6216\u4E0D\u53EF\u8BFB: ", p))
  }
  if (size > 20e6) {
    return(paste0("FAIL: \u6587\u4EF6\u8FC7\u5927\uFF08", round(size / 1e6, 1),
      " MB > 20 MB\uFF09\uFF0C\u8BF7\u7CBE\u7B80\u540E\u518D\u6253\u5F00\u3002"))
  }
  res <- .dairh_bridge_call("viewer", list(path = p), timeout_s = 5)
  if (length(res) > 0L && is.null(attr(res, "bridge_fail"))) {
    return(paste0("OK: \u5DF2\u5728 RStudio Viewer \u6253\u5F00 ", p))
  }
  # \u6865\u4E0D\u53EF\u7528\uFF08CLI/gadget/\u6865\u6389\u7EBF\uFF09\uFF1A\u9000\u7CFB\u7EDF\u6D4F\u89C8\u5668
  shown <- tryCatch({ utils::browseURL(p); TRUE }, error = function(e) FALSE)
  if (isTRUE(shown)) {
    paste0("OK: \u672A\u8FDE\u4E0A RStudio \u80FD\u529B\u6865\uFF0C\u5DF2\u7528\u7CFB\u7EDF\u6D4F\u89C8\u5668\u6253\u5F00 ", p)
  } else {
    paste0("FAIL: \u65E0\u6CD5\u6253\u5F00 ", p, "\uFF08\u6865\u4E0D\u53EF\u7528\u4E14\u6D4F\u89C8\u5668\u8C03\u7528\u5931\u8D25\uFF09")
  }
}

# ---- \u7EAF\u903B\u8F91\uFF1A\u552F\u4E00\u5339\u914D\u66FF\u6362\uFF08\u53EF\u5355\u6D4B\uFF09 -----------------------------------------
# \u8FD4\u56DE list(ok, text, msg)\uFF1Bok=FALSE \u65F6 msg \u8BF4\u660E\u539F\u56E0
.dai_replace_once <- function(text, old_string, new_string) {
  if (!is.character(old_string) || length(old_string) != 1L || !nzchar(old_string)) {
    return(list(ok = FALSE, msg = "FAIL: old_string \u5FC5\u987B\u662F\u975E\u7A7A\u5B57\u7B26\u4E32\u3002"))
  }
  if (is.null(new_string) || !is.character(new_string) || length(new_string) != 1L) {
    return(list(ok = FALSE, msg = "FAIL: new_string \u5FC5\u987B\u662F\u5B57\u7B26\u4E32\uFF08\u53EF\u4E3A\u7A7A\u4E32\uFF09\u3002"))
  }
  pos <- gregexpr(old_string, text, fixed = TRUE)[[1]]
  real <- pos[pos != -1L]
  n1 <- length(real)
  if (n1 == 0L) {
    return(list(
      ok = FALSE,
      msg = paste0(
        "FAIL: \u5728\u6587\u4EF6\u4E2D\u627E\u4E0D\u5230 old_string\uFF08\u8BF7\u786E\u4FDD\u4E0E\u6587\u4EF6\u5185\u5BB9\u9010\u5B57\u7B26\u76F8\u540C\uFF0C\u5305\u62EC\u7A7A\u683C\u3001\u7F29\u8FDB\u3001\u6362\u884C\uFF09\u3002",
        "\u53EF\u4EE5\u5148\u8C03\u7528 read_file \u6838\u5BF9\u539F\u6587\u3002"
      )
    ))
  }
  if (n1 > 1L) {
    return(list(
      ok = FALSE,
      msg = sprintf(
        "FAIL: old_string \u5728\u6587\u4EF6\u4E2D\u51FA\u73B0\u4E86 %d \u6B21\uFF0C\u649E\u4E0A\u591A\u5904\u5339\u914D\u3002\u8BF7\u5728 old_string \u524D\u540E\u591A\u5E26\u4E0A\u51E0\u884C\u72EC\u7279\u4E0A\u4E0B\u6587\uFF0C\u8BA9\u5339\u914D\u552F\u4E00\u3002",
        n1
      )
    ))
  }
  ml <- attr(pos, "match.length")[[1L]]
  new_text <- paste0(
    substring(text, 1L, real[[1L]] - 1L),
    new_string,
    substring(text, real[[1L]] + ml)
  )
  list(ok = TRUE, text = new_text)
}

# \u4E24\u6BB5\u884C\u5411\u91CF\u4E4B\u95F4\u7684\u53D8\u66F4\u7247\u6BB5\uFF08\u4F9B edit/create \u8FD4\u56DE\u7ED9\u6A21\u578B\u770B\uFF09
.dai_diff_excerpt <- function(old_lines, new_lines, max_each = 6L) {
  lo <- length(old_lines)
  ln <- length(new_lines)
  if (lo == 0L && ln == 0L) return(character(0))
  i <- 1L
  while (i <= min(lo, ln) && identical(old_lines[[i]], new_lines[[i]])) i <- i + 1L
  j <- 0L
  while (j < min(lo, ln) - i + 1L &&
    identical(old_lines[[lo - j]], new_lines[[ln - j]])) j <- j + 1L
  removed <- old_lines[max(i, 1L):max(1L, lo - j)]
  added <- new_lines[max(i, 1L):max(1L, ln - j)]
  head_rm <- if (length(removed) > max_each) c(removed[seq_len(max_each)], "...") else removed
  head_ad <- if (length(added) > max_each) c(added[seq_len(max_each)], "...") else added
  c(
    if (length(removed)) paste0("- ", head_rm),
    if (length(added)) paste0("+ ", head_ad)
  )
}

# ---- \u8BFB\u5199\u6587\u4EF6\u5DE5\u5177 -----------------------------------------------------------
.dai_read_file <- function(path, start_line = 1, end_line = NULL, base, restrict) {
  tryCatch(
    {
      p <- .dai_path_guard(path, base = base, restrict = restrict)
      if (dir.exists(p)) return(paste0("FAIL: \u8FD9\u662F\u4E00\u4E2A\u76EE\u5F55\u800C\u975E\u6587\u4EF6: ", p))
      if (!file.exists(p)) return(paste0("FAIL: \u6587\u4EF6\u4E0D\u5B58\u5728: ", p))
      info <- file.info(p)
      if (!is.na(info$size) && info$size > 3e6) {
        return(paste0("FAIL: \u6587\u4EF6\u8FC7\u5927\uFF08", format(info$size), " \u5B57\u8282\uFF09\uFF0C\u8BF7\u53EA\u5BF9\u5E38\u89C4\u6E90\u6587\u4EF6\u64CD\u4F5C\u3002"))
      }
      lines <- readLines(p, warn = FALSE, encoding = "UTF-8", skipNul = TRUE)
      n <- length(lines)
      sl <- max(1L, min(as.integer(start_line %||% 1L), n))
      el_ <- suppressWarnings(as.integer(end_line %||% NA_integer_))
      window <- min(400L, n - sl + 1L)
      el <- if (is.na(el_) || el_ < sl) min(n, sl + window - 1L) else min(n, el_, sl + window - 1L)
      header <- sprintf("[\u6587\u4EF6] %s\uFF08\u5171 %d \u884C\uFF0C\u663E\u793A\u7B2C %d\u2013%d \u884C\uFF09", p, n, sl, el)
      body <- .dai_numbered(lines[seq.int(sl, el)], sl)
      if (el < n) body <- c(body, sprintf("...\uFF08\u540E\u9762\u8FD8\u6709 %d \u884C\u672A\u663E\u793A\uFF09", n - el))
      paste0(c(header, body), collapse = "\n")
    },
    error = function(e) paste0("FAIL: ", conditionMessage(e))
  )
}

.dai_list_files <- function(dir = ".", pattern = NULL, base, restrict) {
  tryCatch(
    {
      d <- .dai_path_guard(
        if (is.null(dir) || !nzchar(dir)) "." else dir,
        base = base, restrict = restrict
      )
      if (!dir.exists(d)) return(paste0("FAIL: \u76EE\u5F55\u4E0D\u5B58\u5728: ", d))
      files <- list.files(
        d,
        pattern = if (is.null(pattern) || !nzchar(pattern) || is.na(pattern)) NULL else pattern,
        recursive = TRUE, all.files = FALSE, full.names = FALSE, ignore.case = TRUE
      )
      n0 <- length(files)
      if (n0 == 0L) {
        return(paste0("[\u76EE\u5F55] ", d, "\uFF08\u6CA1\u6709\u5339\u914D\u7684\u6587\u4EF6\uFF1B\u53EF\u5C1D\u8BD5 pattern \u5982 '\\.R$'\uFF09"))
      }
      show <- files[seq_len(min(n0, 200L))]
      tail_note <- if (n0 > 200L) sprintf("\uFF0C\u4EC5\u663E\u793A\u524D 200 \u4E2A") else ""
      paste0(
        c(
          sprintf("[\u76EE\u5F55] %s\uFF08\u5339\u914D %d \u4E2A\u6587\u4EF6%s\uFF09", d, n0, tail_note),
          paste0("  ", show)
        ),
        collapse = "\n"
      )
    },
    error = function(e) paste0("FAIL: ", conditionMessage(e))
  )
}

.dai_create_file <- function(path, content, base, restrict) {
  tryCatch(
    {
      p <- .dai_path_guard(path, base = base, restrict = restrict)
      if (dir.exists(p)) return(paste0("FAIL: \u76EE\u6807\u662F\u4E00\u4E2A\u76EE\u5F55: ", p))
      existed <- file.exists(p)
      content <- if (is.null(content) || !length(content)) "" else content
      # \u7236\u76EE\u5F55\u4E0D\u5B58\u5728\u65F6\u81EA\u52A8\u521B\u5EFA\uFF08\u5B9E\u6D4B\uFF1A\u5426\u5219\u6A21\u578B\u5E38\u6D6A 3 \u6B65\u53BB\u6392\u67E5 "cannot open the connection"\uFF09
      pdir <- dirname(p)
      if (!dir.exists(pdir)) {
        ok <- dir.create(pdir, recursive = TRUE, showWarnings = FALSE)
        if (!ok && !dir.exists(pdir)) {
          return(paste0("FAIL: \u65E0\u6CD5\u521B\u5EFA\u7236\u76EE\u5F55: ", pdir))
        }
      }
      lines <- strsplit(paste(content, collapse = "\n"), "\n", fixed = TRUE)[[1]]
      if (existed) {
        old_lines <- readLines(p, warn = FALSE, encoding = "UTF-8", skipNul = TRUE)
        writeLines(lines, p, useBytes = TRUE)
        paste0(
          c(
            sprintf("OK: \u5DF2\u8986\u76D6 %s\uFF08\u8986\u76D6\u524D %d \u884C\uFF0C\u73B0 %d \u884C\uFF09", p, length(old_lines), length(lines)),
            "\u53D8\u66F4\u7247\u6BB5\uFF08- =\u5220\u9664\uFF0C+ =\u65B0\u589E\uFF09\uFF1A",
            .dai_diff_excerpt(old_lines, lines)
          ),
          collapse = "\n"
        )
      } else {
        writeLines(lines, p, useBytes = TRUE)
        sprintf("OK: \u5DF2\u521B\u5EFA\u65B0\u6587\u4EF6 %s\uFF08%d \u884C\uFF09", p, length(lines))
      }
    },
    error = function(e) paste0("FAIL: ", conditionMessage(e))
  )
}

.dai_edit_file <- function(path, old_string, new_string, base, restrict) {
  tryCatch(
    {
      p <- .dai_path_guard(path, base = base, restrict = restrict)
      if (!file.exists(p)) return(paste0("FAIL: \u6587\u4EF6\u4E0D\u5B58\u5728: ", p))
      lines <- readLines(p, warn = FALSE, encoding = "UTF-8", skipNul = TRUE)
      text <- paste(lines, collapse = "\n")
      rep <- .dai_replace_once(text, old_string, new_string)
      if (!rep$ok) return(paste0(rep$msg, "\n\u6587\u4EF6: ", p))
      new_lines <- strsplit(rep$text, "\n", fixed = TRUE)[[1]]
      writeLines(new_lines, p, useBytes = TRUE)
      dairh_nav(p, 1L)
      paste0(
        c(
          sprintf("OK: \u5DF2\u7F16\u8F91 %s", p),
          "\u53D8\u66F4\u7247\u6BB5\uFF08- =\u5220\u9664\uFF0C+ =\u65B0\u589E\uFF09\uFF1A",
          .dai_diff_excerpt(lines, new_lines)
        ),
        collapse = "\n"
      )
    },
    error = function(e) paste0("FAIL: ", conditionMessage(e))
  )
}

# ---- \u8FD0\u884C R \u4EE3\u7801\uFF08callr \u5B50\u8FDB\u7A0B\uFF09 ---------------------------------------------
.dai_run_r_code <- function(code, timeout_sec = 60) {
  code <- paste(as.character(code), collapse = "\n")
  if (!nzchar(code)) return("FAIL: code \u4E0D\u80FD\u4E3A\u7A7A\u3002")
  to <- suppressWarnings(as.numeric(timeout_sec %||% 60))
  if (is.na(to)) to <- 60
  to <- min(max(to, 5), 600)

  res <- tryCatch(
    callr::r(
      function(code_text) {
        exprs <- tryCatch(parse(text = code_text), error = function(e) e)
        if (inherits(exprs, "error")) {
          return(list(status = "parse_error",
            message = conditionMessage(exprs)))
        }
        msg_parts <- character(0)
        val <- NULL
        out <- utils::capture.output(
          val <- tryCatch(
            withCallingHandlers(
              suppressWarnings(eval(exprs, envir = new.env(parent = .GlobalEnv))),
              message = function(m) {
                msg_parts <<- c(msg_parts, conditionMessage(m))
                invokeRestart("muffleMessage")
              }
            ),
            error = function(e) e
          )
        )
        if (inherits(val, "error")) {
          return(list(status = "error",
            message = conditionMessage(val),
            output = out, messages = utils::head(msg_parts, 20)))
        }
        value_info <- "\uFF08\u65E0\u663E\u5F0F\u8FD4\u56DE\u503C\uFF09"
        if (!is.null(val)) {
          value_info <- utils::capture.output(
            str(val, max.level = 2, vec.len = 6, digits.d = 4)
          )
        }
        list(status = "ok", output = out, value = value_info,
          messages = utils::head(msg_parts, 20))
      },
      args = list(code_text = code),
      libpath = .libPaths(),
      show = FALSE,
      timeout = to
    ),
    error = function(e) {
      msg <- conditionMessage(e)
      if (grepl("timed out|timeout", msg, ignore.case = TRUE)) {
        list(status = "timeout", message = sprintf("\u4EE3\u7801\u6267\u884C\u8D85\u8FC7 %s \u79D2\u88AB\u7EC8\u6B62", to))
      } else {
        list(status = "crash", message = .dai_clip(msg, 4000))
      }
    }
  )

  if (identical(res$status, "parse_error")) {
    return(paste0(
      "FAIL: \u4EE3\u7801\u89E3\u6790\u5931\u8D25\uFF08\u8BED\u6CD5\u9519\u8BEF\uFF09\uFF1A", .dai_clip(res$message, 2000),
      "\n\uFF08\u8BF7\u4FEE\u6B63\u8BED\u6CD5\u540E\u91CD\u8BD5\uFF09"
    ))
  }
  if (identical(res$status, "error")) {
    return(paste0(
      "FAIL: \u4EE3\u7801\u8FD0\u884C\u62A5\u9519\uFF1A", .dai_clip(res$message, 4000),
      "\nstdout/stderr\uFF1A\n", .dai_clip(res$output, 4000),
      "\n\uFF08\u8BF7\u6839\u636E\u9519\u8BEF\u4FEE\u6B63\u4EE3\u7801\u540E\u91CD\u8BD5\uFF09"
    ))
  }
  if (identical(res$status, "timeout")) {
    return(paste0("FAIL: ", res$message, "\u3002\u8BF7\u628A\u5927\u4EFB\u52A1\u62C6\u5C0F\u3001\u63D0\u9AD8 timeout_sec\uFF0C\u6216\u51CF\u5C11\u8BA1\u7B97\u91CF\u540E\u91CD\u8BD5\u3002"))
  }
  if (identical(res$status, "crash")) {
    return(paste0("FAIL: \u5B50\u8FDB\u7A0B\u5F02\u5E38\uFF1A", res$message))
  }

  parts <- c("OK: \u4EE3\u7801\u6267\u884C\u5B8C\u6210\u3002")
  if (length(res$output) && any(nzchar(res$output))) {
    parts <- c(parts, "---- stdout/stderr ----", .dai_clip(res$output, 5000))
  }
  if (length(res$messages)) {
    parts <- c(parts, "---- messages ----", .dai_clip(res$messages, 1000))
  }
  parts <- c(parts, "---- \u8FD4\u56DE\u503C ----", .dai_clip(res$value, 3000))
  paste(parts, collapse = "\n")
}

# ---- R \u6587\u6863 -----------------------------------------------------------------
# \u4ECE\u67D0\u4E2A\u5305\u76EE\u5F55\u7684 AnIndex\uFF08\u522B\u540D<TAB>\u4E3B\u9898\uFF09\u91CC\u89E3\u6790\u51FA\u53EF\u67E5\u7684 topic \u952E
.dai_help_keys <- function(pkgdir, topic) {
  an <- file.path(pkgdir, "help", "AnIndex")
  if (!file.exists(an)) return(character(0))
  idx <- tryCatch(
    read.table(an, sep = "\t", quote = "", comment.char = "",
      header = FALSE, colClasses = "character", fill = TRUE,
      blank.lines.skip = TRUE
    ),
    error = function(e) NULL
  )
  if (is.null(idx) || ncol(idx) < 2L || nrow(idx) == 0L) return(character(0))
  keys <- character(0)
  hit2 <- which(idx[[2]] == topic)
  if (length(hit2)) keys <- c(keys, utils::head(idx[[2]][hit2], 1L))
  hit1 <- which(idx[[1]] == topic)
  if (length(hit1)) keys <- c(keys, utils::head(idx[[2]][hit1], 1L))
  unique(keys)
}

.dai_get_r_help <- function(topic, package = NULL) {
  topic <- paste(as.character(topic), collapse = " ")
  tryCatch(
    {
      libs <- .libPaths()
      if (!is.null(package) && nzchar(package) && !is.na(package)) {
        pkg_list <- package
      } else {
        # \u65E0\u6307\u5B9A\u5305\uFF1A\u4F18\u5148\u6838\u5FC3\u5305\uFF0C\u6309\u6210\u672C\u987A\u5E8F\u5C1D\u8BD5
        core <- c("base", "stats", "utils", "graphics", "grDevices", "datasets")
        rest <- tryCatch(list.files(libs[[1]]), error = function(e) character(0))
        pkg_list <- c(core, setdiff(rest, core))
      }
      for (lib in libs) {
        for (p in pkg_list) {
          pkgdir <- file.path(lib, p)
          if (!dir.exists(pkgdir)) next
          keys <- .dai_help_keys(pkgdir, topic)
          for (key in keys) {
            rd <- tryCatch(
              # utils:::.getHelpFile \u662f\u552f\u4e00\u80fd\u8bfb Rd \u6570\u636e\u5e93\u7684\u5165\u53e3\uFF0c\u4f46\u672a\u5bfc\u51fa\uFF1b
              # \u7528 get() \u53d6\uFF0c\u907f\u514d ::: \u89e6\u53d1 R CMD check \u7684\u672a\u5bfc\u51fa\u8b66\u544a
              get(".getHelpFile", envir = asNamespace("utils"))(file.path(pkgdir, "help", key)),
              error = function(e) NULL
            )
            if (is.null(rd)) next
            txt <- capture.output(tools::Rd2txt(rd))
            return(paste0(
              c(
                sprintf("[\u5E2E\u52A9] topic=%s (package=%s)", topic, p),
                .dai_clip(txt, 18000)
              ),
              collapse = "\n"
            ))
          }
        }
      }
      paste0(
        "\u672A\u627E\u5230 topic=", topic,
        if (!is.null(package) && nzchar(package)) sprintf("\uFF08package=%s\uFF09", package) else "",
        " \u7684\u5E2E\u52A9\u9875\u3002\u8BF7\u786E\u8BA4\u51FD\u6570\u540D\u4E0E\u5305\u540D\u62FC\u5199\uFF08\u5DE5\u5177\u4E0D\u4F1A\u62FC\u63A5\u672A\u5B89\u88C5\u7684\u5305\uFF09\u3002"
      )
    },
    error = function(e) paste0("FAIL: \u83B7\u53D6\u5E2E\u52A9\u5931\u8D25\uFF1A", conditionMessage(e))
  )
}

# ---- \u73AF\u5883\u6458\u8981 ---------------------------------------------------------------
.dai_workspace_summary <- function() {
  objs <- ls(globalenv(), all.names = FALSE, sorted = TRUE)
  if (!length(objs)) return("\u5DE5\u4F5C\u533A\u76EE\u524D\u6CA1\u6709\u5168\u5C40\u5BF9\u8C61\u3002")
  objs <- utils::head(objs, 80)
  info <- vapply(objs, function(nm) {
    o <- tryCatch(get(nm, envir = globalenv()), error = function(e) NA)
    if (is.na(o)[1] && !is.list(o)) return(NA_character_)
    cls <- tryCatch(class(o)[1], error = function(e) "?")
    dim_txt <- tryCatch(
      {
        d <- dim(o)
        if (length(d) == 2L) sprintf(" [%d x %d]", d[1], d[2]) else sprintf(" (len %d)", length(o))
      },
      error = function(e) ""
    )
    paste0(cls, dim_txt)
  }, character(1), USE.NAMES = TRUE)
  paste0(
    c(
      sprintf("\u5168\u5C40\u73AF\u5883\u5BF9\u8C61\uFF08\u524D %d \u4E2A\uFF09\uFF1A", length(info)),
      sprintf("  %s : %s", names(info), info),
      "",
      paste0("\u5DF2\u52A0\u8F7D\u7684\u5305(", length(search()) - 1L, ")\uFF1A",
        paste(utils::head(search()[-1], 12), collapse = ", ")
      )
    ),
    collapse = "\n"
  )
}

# ---- \u7EC4\u88C5\u5E76\u6CE8\u518C\u5DE5\u5177 ---------------------------------------------------------

#' \u6784\u5EFA DaiRH Agent \u7684\u5168\u90E8\u5DE5\u5177
#'
#' \u4F9D\u636E\u914D\u7F6E\u51B3\u5B9A\u6CE8\u518C\u54EA\u4E9B\u5DE5\u5177\uFF1Aallow_edit \u63A7\u5236 create_file/edit_file\uFF0C
#' allow_run \u63A7\u5236 run_r_code\uFF1B\u8FD4\u56DE ellmer tool \u5BF9\u8C61\u5217\u8868\uFF08\u672A\u6CE8\u518C\u5230\u4F1A\u8BDD\uFF09\u3002
#' \u6BCF\u4E2A\u5DE5\u5177\u90FD\u4F1A\u7ECF [harness \u5C42][dairh_register_tool] \u5305\u88C5\uFF08\u94A9\u5B50/\u786C\u9884\u7B97/trace\uFF09\uFF0C
#' \u5E76\u5408\u5E76 `dairh_register_tool()` \u6CE8\u518C\u7684\u81EA\u5B9A\u4E49\u5DE5\u5177\u3002
#'
#' @param cfg [dairh_config_get()] \u7684\u914D\u7F6E\u5217\u8868
#' @param state harness \u4F1A\u8BDD\u72B6\u6001\uFF08\u4E00\u822C\u7531 [dairh_new_agent()] \u521B\u5EFA\u5E76\u6301\u6709\uFF1B
#'   \u76F4\u63A5\u8C03\u7528\u672C\u51FD\u6570\u65F6\u81EA\u52A8\u65B0\u5EFA\uFF09
#' @param exclude \u4ECE\u6700\u7EC8\u5DE5\u5177\u96C6\u91CC\u6392\u9664\u7684\u5DE5\u5177\u540D\uFF08\u5B50\u4EE3\u7406\u6784\u5EFA\u65F6\u7528\u5B83
#'   \u6392\u9664 delegate_task \u81EA\u8EAB\uFF0C\u9632\u9012\u5F52\uFF1B\u4E00\u822C\u7528\u4E0D\u5230\uFF09
#' @return \u547D\u540D\u5217\u8868\uFF1B\u6BCF\u4E2A\u5143\u7D20\u662F ellmer Tool \u5BF9\u8C61\uFF08\u53EF\u7528 `chat$register_tool()` \u6CE8\u518C\uFF09\uFF1B
#'   \u9644\u5C5E\u5C5E\u6027 `.dairh_state` \u662F\u5BF9\u5E94\u7684\u72B6\u6001\u73AF\u5883
#' @export
dairh_agent_tools <- function(cfg = dairh_config_get(), state = .dairh_new_state(cfg),
                              exclude = character(0)) {
  base <- dairh_base_dir()
  restrict <- isTRUE(cfg$restrict_paths)
  allow_edit <- isTRUE(cfg$allow_edit)
  allow_run <- isTRUE(cfg$allow_run)
  # \u8BA1\u5212\u6A21\u5F0F\uFF1A\u6700\u7EC8\u5DE5\u5177\u96C6\u7269\u7406\u88C1\u6389\u5199\u6587\u4EF6/\u6267\u884C/\u4EA4\u4ED8\u7C7B\uFF08\u89C1 .dairh_plan_dropped_tools\uFF09
  plan <- .dairh_is_plan_mode(cfg)
  tools <- list()

  tools$read_file <- ellmer::tool(
    function(path, start_line = 1, end_line = NULL) {
      .dai_read_file(path, start_line, end_line, base = base, restrict = restrict)
    },
    "\u8BFB\u53D6\u9879\u76EE\u5185\u6587\u4EF6\u5185\u5BB9\uFF0C\u8FD4\u56DE\u5E26\u884C\u53F7\u7684\u6587\u672C\u3002\u8BFB\u5927\u6587\u4EF6\u65F6\u7528 start_line/end_line \u5206\u6BB5\u8BFB\u3002",
    arguments = list(
      path = ellmer::type_string("\u6587\u4EF6\u76F8\u5BF9\u8DEF\u5F84\u6216\u7EDD\u5BF9\u8DEF\u5F84", required = TRUE),
      start_line = ellmer::type_integer("\u8D77\u59CB\u884C\uFF0C\u9ED8\u8BA4 1", required = FALSE),
      end_line = ellmer::type_integer("\u7ED3\u675F\u884C\uFF08\u53EF\u9009\uFF0C\u9ED8\u8BA4\u8BFB\u5230\u7A97\u53E3\u4E0A\u9650\uFF09", required = FALSE)
    )
  )

  tools$list_files <- ellmer::tool(
    function(dir = ".", pattern = NULL) {
      .dai_list_files(dir, pattern, base = base, restrict = restrict)
    },
    "\u5217\u51FA\u9879\u76EE\u76EE\u5F55\u4E0B\u7684\u6587\u4EF6\uFF08\u9012\u5F52\uFF09\u3002pattern \u662F\u6B63\u5219\u8868\u8FBE\u5F0F\uFF0C\u4F8B\u5982 \\.R$ \u53EA\u770B R \u811A\u672C\u3002",
    arguments = list(
      dir = ellmer::type_string("\u76EE\u5F55\u8DEF\u5F84\uFF0C\u9ED8\u8BA4\u9879\u76EE\u6839\u76EE\u5F55", required = FALSE),
      pattern = ellmer::type_string("\u6587\u4EF6\u540D\u8FC7\u6EE4\u6B63\u5219\uFF0C\u53EF\u9009", required = FALSE)
    )
  )

  if (allow_edit) {
    tools$create_file <- ellmer::tool(
      function(path, content) {
        .dai_create_file(path, content, base = base, restrict = restrict)
      },
      "\u521B\u5EFA\u65B0\u6587\u4EF6\uFF08\u6216\u8986\u76D6\u5DF2\u6709\u6587\u4EF6\uFF09\u5E76\u5199\u5165\u5185\u5BB9\u3002\u8986\u76D6\u65F6\u540C\u6837\u5141\u8BB8\uFF0C\u4F46\u4F18\u5148\u4F7F\u7528 edit_file \u505A\u5C0F\u6539\u52A8\u3002",
      arguments = list(
        path = ellmer::type_string("\u76EE\u6807\u6587\u4EF6\u8DEF\u5F84", required = TRUE),
        content = ellmer::type_string("\u8981\u5199\u5165\u7684\u5B8C\u6574\u6587\u4EF6\u5185\u5BB9", required = TRUE)
      )
    )

    tools$edit_file <- ellmer::tool(
      function(path, old_string, new_string) {
        .dai_edit_file(path, old_string, new_string, base = base, restrict = restrict)
      },
      "\u5BF9\u6587\u4EF6\u505A\u7CBE\u786E\u66FF\u6362\uFF1Aold_string \u5FC5\u987B\u4E0E\u6587\u4EF6\u5185\u5BB9\u9010\u5B57\u7B26\u76F8\u540C\u4E14\u5728\u6587\u4EF6\u4E2D\u552F\u4E00\uFF08\u5EFA\u8BAE\u524D\u540E\u591A\u5E26\u51E0\u884C\u4E0A\u4E0B\u6587\u4FDD\u8BC1\u552F\u4E00\uFF09\u3002new_string \u4E3A\u66FF\u6362\u540E\u7684\u6587\u672C\uFF0C\u53EF\u4EE5\u4E3A\u7A7A\u4E32\uFF08\u5220\u9664\uFF09\u3002",
      arguments = list(
        path = ellmer::type_string("\u76EE\u6807\u6587\u4EF6\u8DEF\u5F84", required = TRUE),
        old_string = ellmer::type_string("\u8981\u66FF\u6362\u7684\u539F\u6587\uFF08\u9010\u5B57\u7B26\u4E00\u81F4\uFF09", required = TRUE),
        new_string = ellmer::type_string("\u66FF\u6362\u540E\u7684\u6587\u672C", required = TRUE)
      )
    )
  }

  if (allow_run) {
    tools$run_r_code <- ellmer::tool(
      function(code, timeout_sec = 60) {
        .dai_run_r_code(code, timeout_sec)
      },
      "\u5728\u9694\u79BB\u5B50\u8FDB\u7A0B\u4E2D\u6267\u884C\u4E00\u6BB5 R \u4EE3\u7801\uFF08\u4E0D\u5F71\u54CD\u5F53\u524D RStudio \u4F1A\u8BDD\uFF09\uFF0C\u8FD4\u56DE\u8F93\u51FA\u4E0E\u7ED3\u679C\u6458\u8981\u3002\u62A5\u9519\u4F1A\u539F\u6837\u8FD4\u56DE\uFF0C\u8BF7\u6839\u636E\u62A5\u9519\u81EA\u6211\u4FEE\u6B63\u3002",
      arguments = list(
        code = ellmer::type_string("\u8981\u6267\u884C\u7684 R \u4EE3\u7801", required = TRUE),
        timeout_sec = ellmer::type_number("\u8D85\u65F6\u79D2\u6570\uFF0C\u9ED8\u8BA4 60\uFF0C\u8303\u56F4 5\u2013600", required = FALSE)
      )
    )
  }

  tools$get_r_help <- ellmer::tool(
    function(topic, package = NULL) {
      .dai_get_r_help(topic, package)
    },
    "\u67E5\u8BE2 R \u51FD\u6570/\u4E3B\u9898\u7684\u5E2E\u52A9\u6587\u6863\uFF08\u6309 Rd \u6E32\u67D3\u4E3A\u7EAF\u6587\u672C\uFF09\u3002",
    arguments = list(
      topic = ellmer::type_string("\u5E2E\u52A9\u4E3B\u9898\uFF0C\u901A\u5E38\u662F\u51FD\u6570\u540D", required = TRUE),
      package = ellmer::type_string("\u5305\u540D\uFF0C\u901A\u5E38\u7559\u7A7A\u81EA\u52A8\u5B9A\u4F4D", required = FALSE)
    )
  )

  tools$workspace_summary <- ellmer::tool(
    function() {
      ws <- .dairh_bridge_get("/workspace")
      if (length(ws) && nzchar(ws)) ws else .dai_workspace_summary()
    },
    "\u67E5\u770B\u5F53\u524D RStudio \u5DE5\u4F5C\u533A\u6458\u8981\uFF1A\u5168\u5C40\u53D8\u91CF\uFF08\u540D\u79F0/\u7C7B\u578B/\u5C3A\u5BF8\uFF09\u4E0E\u5DF2\u52A0\u8F7D\u7684\u5305\u3002",
    arguments = list()
  )

  tools$get_editor_context <- ellmer::tool(
    function() {
      # \u5FEB\u7167\u5F0F\u67B6\u6784\uFF1A\u9762\u677F\u53EA\u8BFB\u4E3B\u4F1A\u8BDD\u5199\u5165\u7684 context-snapshot.json\uFF08\u540C\u6B65\u3001\u77AC\u53D1\uFF09\u3002
      # \u5FEB\u7167\u7531\u4E3B\u4F1A\u8BDD\u6CF5\u5728\u6BCF\u6B21\u63A7\u5236\u53F0\u4EFB\u52A1\u8FB9\u754C\u5237\u65B0\uFF08\u4FDD\u5B58\u6587\u4EF6+\u6309\u56DE\u8F66\u5373\u53EF\u5F3A\u5236\u5237\u65B0\uFF09\u3002
      # \u5982\u5FEB\u7167\u8FC7\u671F\uFF0C\u6A21\u578B\u5E94\u6539\u7528 read_file \u6309\u8DEF\u5F84\u8BFB\u53D6\u6700\u65B0\u5185\u5BB9\u3002
      j <- .dairh_bridge_snapshot()
      if (!is.null(j) && !is.null(j$context) &&
          nzchar(as.character(j$context %||% ""))) {
        paste0(
          "\u3010\u6CE8\u610F\u3011\u7F16\u8F91\u5668\u4E0A\u4E0B\u6587\u4E3A\u5FEB\u7167\u5F0F\uFF0C\u5FEB\u7167\u65F6\u95F4: ",
          as.character(j$time %||% "?"),
          "\uFF08\u968F RStudio \u63A7\u5236\u53F0\u6D3B\u52A8\u81EA\u52A8\u5237\u65B0\uFF1B\u82E5\u65E9\u4E8E\u4F60\u6700\u8FD1\u7684\u4FEE\u6539\uFF0C\u8BF7\u6539\u7528 read_file \u6309\u8DEF\u5F84\u8BFB\u53D6\uFF09\u3002\n",
          "\u3010\u57FA\u7840\u4FE1\u606F\u3011\u5DE5\u4F5C\u76EE\u5F55: ",
          as.character(j$base_dir %||% dairh_base_dir()),
          "\n", as.character(j$context)
        )
      } else {
        snap <- getOption("daiRH.editor_snapshot")
        if (length(snap) && nzchar(snap)) {
          sbase <- getOption("daiRH.snapshot_base")
          paste0(
            "\u3010\u6CE8\u610F\u3011\u5FEB\u7167\u6587\u4EF6\u5C1A\u672A\u751F\u6210\uFF1B\u4EE5\u4E0B\u662F\u9762\u677F\u542F\u52A8\u90A3\u4E00\u523B\u7684\u7F16\u8F91\u5668\u5FEB\u7167\uFF0C",
            "\u53EF\u80FD\u4E0D\u542B\u542F\u52A8\u4E4B\u540E\u7684\u4FEE\u6539\u3002\u5982\u9700\u6700\u65B0\u5185\u5BB9\u8BF7\u7528 read_file \u6309\u8DEF\u5F84\u8BFB\u53D6\u3002\n",
            "\u3010\u57FA\u7840\u4FE1\u606F\u3011\u5DE5\u4F5C\u76EE\u5F55: ",
            if (length(sbase) && nzchar(sbase)) sbase else dairh_base_dir(),
            "\n", snap
          )
        } else {
          paste0(
            "\u3010\u57FA\u7840\u4FE1\u606F\u3011\u5DE5\u4F5C\u76EE\u5F55: ", dairh_base_dir(),
            "\n", dairh_editor_context_text()
          )
        }
      }
    },
    "\u8BFB\u53D6\u6211\u5F53\u524D\u5728 RStudio \u91CC\u6253\u5F00\u7684\u6587\u4EF6\u5185\u5BB9\u4E0E\u9009\u533A\u3002\u5F00\u59CB\u5904\u7406\u4E0E\u5F53\u524D\u6587\u4EF6\u76F8\u5173\u7684\u4EFB\u52A1\u524D\uFF0C\u5E94\u5148\u8C03\u7528\u6B64\u5DE5\u5177\u3002",
    arguments = list()
  )

  tools$show_plot <- ellmer::tool(
    function(path) {
      r <- .dai_show_plot_prep(path, base = base, restrict = restrict)
      if (isTRUE(r$ok)) {
        # magick \u4E0D\u662F\u786C\u4F9D\u8D56\uFF08\u4E0D\u58F0\u660E\u5728 DESCRIPTION\uFF09\uFF1Aresize="low" \u9700\u8981\u5B83\uFF0C
        # \u6CA1\u88C5\u65F6\uFF08\u5982 CI\uFF09\u4F1A\u5728 content_image_file \u5185\u90E8\u62FC\u62BC\u51FA\u9519\uFF1B\u964D\u7EA7 resize="none"
        # \uFF08\u53D1\u539F\u56FE\u4E0D\u538B\u7F29\uFF09\u529F\u80FD\u4E0D\u65AD\u3002
        r$img <- tryCatch(
          ellmer::content_image_file(r$msg, resize = "low"),
          error = function(e) ellmer::content_image_file(r$msg, resize = "none")
        )
        # 0.5 \u76F4\u8FD4\uFF1A\u6587\u672C + \u56FE\u7247\u4F5C\u4E3A\u5DE5\u5177\u7ED3\u679C\u8FDB\u5BF9\u8BDD\uFF08ellmer 0.5 \u5B98\u65B9\u652F\u6301 Content \u5217\u8868\uFF09\u3002
        # \u9762\u677F\u5DE5\u5177\u5361\u7247\u5185\u8054\u6E32\u67D3\u3001\u968F\u4F1A\u8BDD\u5386\u53F2\u91CD\u653E\uFF1B\u652F\u6301\u89C6\u89C9\u7684\u7AEF\u70B9\u4E0A\u6A21\u578B\u80FD\u771F\u6B63\u770B\u56FE\u5206\u6790\uFF0C
        # \u7EAF\u6587\u672C\u7AEF\u70B9\u53EA\u770B\u5230\u6587\u5B57\u90E8\u5206\uFF08openai_compatible \u8D70\u964D\u7EA7\u56DE\u9000\uFF0C\u5B9E\u6D4B\u65E0\u5BB3\uFF09\u3002
        list(
          ellmer::ContentText(text = paste0(
            "OK: \u56FE\u7247\u5DF2\u8FDB\u5165\u5BF9\u8BDD\uFF08", r$msg,
            "\uFF09\u3002\u8BF7\u57FA\u4E8E\u56FE\u7247\u7EE7\u7EED\u5206\u6790\u3002")),
          r$img
        )
      } else {
        r$msg
      }
    },
    "\u628A\u5DF2\u751F\u6210\u7684\u56FE\u7247\uFF08png/jpg/webp\uFF0C\u22644MB\uFF09\u76F4\u63A5\u8FD4\u56DE\u8FDB\u5BF9\u8BDD\uFF1A\u804A\u5929\u91CC\u5185\u8054\u663E\u793A\uFF0C\u652F\u6301\u89C6\u89C9\u7684\u6A21\u578B\u8FD8\u80FD\u770B\u56FE\u5206\u6790\u3002",
    arguments = list(
      path = ellmer::type_string("\u56FE\u7247\u6587\u4EF6\u8DEF\u5F84\uFF08\u76F8\u5BF9\u9879\u76EE\u76EE\u5F55\u6216\u7EDD\u5BF9\u8DEF\u5F84\uFF09", required = TRUE)
    )
  )

  tools$show_html <- ellmer::tool(
    function(path) {
      .dai_show_html(path, base = base, restrict = restrict)
    },
    "\u628A\u9879\u76EE\u91CC\u7684 HTML \u6587\u4EF6\uFF08\u5982 leaflet/mapview \u4EA4\u4E92\u5730\u56FE\u3001htmlwidgets \u8F93\u51FA\uFF09\u5728 RStudio Viewer \u91CC\u6253\u5F00\uFF1B\u672A\u8FDE\u4E0A\u80FD\u529B\u6865\u65F6\u9000\u7CFB\u7EDF\u6D4F\u89C8\u5668\u3002HTML \u9700\u5148\u4FDD\u5B58\u5230\u9879\u76EE\u76EE\u5F55\u5185\u3002",
    arguments = list(
      path = ellmer::type_string("HTML \u6587\u4EF6\u8DEF\u5F84\uFF08\u76F8\u5BF9\u9879\u76EE\u76EE\u5F55\u6216\u7EDD\u5BF9\u8DEF\u5F84\uFF09", required = TRUE)
    )
  )

  tools$read_skill <- ellmer::tool(
    function(name = "") {
      .dai_read_skill(name)
    },
    "\u67E5\u770B\u9879\u76EE\u6280\u80FD\u5E93\u5E76\u6309\u9700\u8BFB\u53D6\uFF1aname \u7559\u7A7A\u5217\u51FA\u53EF\u7528\u6280\u80FD\uFF0C\u7ED9\u5B9A\u540D\u5B57\u8FD4\u56DE\u8BE5\u6280\u80FD\u7684\u5B8C\u6574\u8BF4\u660E\uFF08\u89C4\u7A0B/\u6A21\u677F/\u9886\u57DF\u77E5\u8BC6\uFF09\u3002\u9762\u5BF9\u4E0D\u719F\u6089\u7684\u9886\u57DF\u4EFB\u52A1\u65F6\u5148\u5217\u4E00\u4E0B\u6280\u80FD\u5E93\u3002",
    arguments = list(
      name = ellmer::type_string("\u6280\u80FD\u540D\uFF1B\u7559\u7A7A\u5217\u51FA\u5168\u90E8", required = FALSE)
    )
  )

  if (isTRUE(cfg$allow_subagent)) {
    tools$delegate_task <- ellmer::tool(
      function(task) {
        .dairh_delegate_task(task, cfg = cfg, state = state)
      },
      "\u628A\u4E00\u4E2A\u81EA\u5305\u542B\u7684\u5B50\u4EFB\u52A1\u59D4\u6D3E\u7ED9\u5B50\u4EE3\u7406\u6267\u884C\uFF08\u5B50\u4EE3\u7406\u6709\u540C\u6837\u7684\u5DE5\u5177\u4F46\u770B\u4E0D\u5230\u5F53\u524D\u5BF9\u8BDD\uFF09\uFF0C\u9002\u5408\u6279\u91CF\u9A8C\u8BC1\u3001\u72EC\u7ACB\u8C03\u7814\u7B49\u8DD1\u817F\u6D3B\u3002\u4EFB\u52A1\u63CF\u8FF0\u5FC5\u987B\u81EA\u5305\u542B\uFF1A\u76EE\u6807\u3001\u6D89\u53CA\u7684\u6587\u4EF6\u8DEF\u5F84\u3001\u9A8C\u6536\u6807\u51C6\u3002",
      arguments = list(
        task = ellmer::type_string("\u5B50\u4EFB\u52A1\u63CF\u8FF0\uFF08\u81EA\u5305\u542B\uFF09", required = TRUE)
      )
    )
  }

  # harness \u5C42\uFF1A\u5185\u7F6E\u5DE5\u5177\u9010\u4E00\u5305\u88C5\uFF08\u94A9\u5B50/\u786C\u9884\u7B97/trace\uFF09\uFF0C
  # \u5E76\u4FEE\u6B63 ellmer \u5BF9\u533F\u540D\u51FD\u6570\u7684\u8BA1\u6570\u5668\u547D\u540D\uFF08\u5426\u5219\u6A21\u578B\u770B\u5230\u7684\u662F tool_001... \uFF09\u3002
  builtin_names <- names(tools)
  tools <- lapply(builtin_names, function(nm) {
    t <- tools[[nm]]
    .dairh_wrap_tool(nm, t, t@description, t@arguments, state)
  })
  names(tools) <- builtin_names

  # \u5408\u5E76\u6CE8\u518C\u8868\uFF1A\u81EA\u5B9A\u4E49\u5DE5\u5177\u8FFD\u52A0\uFF1B\u4E0E\u5185\u7F6E\u540C\u540D\u7684\u6CE8\u518C\u9879\u8986\u76D6\u5185\u7F6E\u3002
  reg <- .dairh_harness_env$tools
  keep <- setdiff(names(tools), names(reg))
  final <- tools[keep]
  for (nm in names(reg)) {
    spec <- reg[[nm]]
    t <- tryCatch(
      .dairh_wrap_tool(nm, spec$fn, spec$description, spec$arguments, state),
      error = function(e) {
        warning(sprintf("\u81EA\u5B9A\u4E49\u5DE5\u5177 %s \u6784\u5EFA\u5931\u8D25\uFF0C\u5DF2\u8DF3\u8FC7\uFF1A%s", nm, conditionMessage(e)),
          call. = FALSE)
        NULL
      }
    )
    if (!is.null(t)) final[[nm]] <- t
  }

  # \u8BA1\u5212\u6A21\u5F0F\uFF1A\u4ECE\u6700\u7EC8\u5DE5\u5177\u96C6\u7269\u7406\u88C1\u6389\u5199\u6587\u4EF6/\u6267\u884C/\u4EA4\u4ED8\u7C7B\uFF08\u975E\u63D0\u793A\u8BCD\u529D\u544A\uFF1B\u81EA\u5B9A\u4E49\u5DE5\u5177\u4E0D\u88C1\uFF09
  if (plan) final <- final[setdiff(names(final), .dairh_plan_dropped_tools)]

  # \u6DF1\u5EA6\u9501\uFF1A\u5B50\u4EE3\u7406\u6784\u5EFA\u5DE5\u5177\u96C6\u65F6\u6392\u9664 delegate_task\uFF08cfg$allow_subagent \u518D\u5173\u4E00\u5C42\u95F8\uFF09
  if (length(exclude)) final <- final[setdiff(names(final), exclude)]
  attr(final, ".dairh_state") <- state
  final
}
