# DaiRH \u4E0A\u4E0B\u6587\u538B\u7F29 -------------------------------------------------------------
# \u624B\u52A8\u538B\u7F29\uFF08\u9762\u677F\u6309\u94AE / CLI \u7684 /compact\uFF09\u5171\u7528\u6838\u5FC3\uFF0C\u4E09\u6B65\uFF1A
#   1) \u628A\u5F53\u524D\u5BF9\u8BDD\uFF08\u542B\u5DE5\u5177\u8C03\u7528\u94FE\uFF09\u6E32\u67D3\u6210\u7EAF\u6587\u672C transcript\uFF1B
#   2) \u4E00\u6B21\u6027\u65E0\u5DE5\u5177 Chat\uFF08\u4E3B\u6A21\u578B\uFF09\u751F\u6210\u7ED3\u6784\u5316\u6458\u8981\u2014\u2014\u603B\u7ED3\u5668\u8D70 dairh_client()
#      \u88F8\u6784\u9020\uFF0C\u4E0D\u6CE8\u518C\u4EFB\u4F55\u5DE5\u5177\uFF1B\u7528\u91CF\u7167\u5E38\u8FDB usage \u65E5\u5FD7\uFF08\u4E5F\u662F\u4E00\u6B21\u771F\u5B9E\u8BF7\u6C42\uFF09\uFF1B
#   3) set_turns() \u91CD\u6C34\u5408\uFF1Auser(\u6458\u8981) + assistant(\u786E\u8BA4) \u4E24\u8F6E\uFF0C\u5E76\u91CD\u7F6E\u786C\u9884\u7B97
#      \uFF08n_calls \u5F52\u96F6\u3001last_user_n \u7F6E NA\uFF09+ trace compact \u4E8B\u4EF6\u3002
# \u9762\u677F\u4FA7\u5206\u4E24\u6B65\u7528\uFF1A\u5148 .dairh_compact_summary()\uFF08\u8981\u5728 new_chat() \u5B58\u6863\u4E4B\u524D\u8BFB\uFF09\uFF0C
# \u518D .dairh_compact_apply()\uFF1BCLI \u7528\u4E00\u6B65\u5230\u4F4D\u7684 .dairh_compact_turns()\u3002
# \u672C\u6587\u4EF6\u4E0D\u78B0 UI \u4E0E shinychat\uFF08\u5B58\u6863/\u6A2A\u5E45\u5728 app_shiny.R \u4FA7\u5B8C\u6210\uFF09\u3002

.dairh_compact_prompt <- function() {
  paste(c(
    "\u4F60\u662F\u5BF9\u8BDD\u538B\u7F29\u5668\uFF1A\u628A\u4E00\u4EFD Agent \u5DE5\u4F5C\u5BF9\u8BDD\u7684\u5B8C\u6574\u8BB0\u5F55\u603B\u7ED3\u6210\u540E\u7EED\u5DE5\u4F5C\u6240\u9700\u7684\u7D27\u51D1\u4E0A\u4E0B\u6587\u3002",
    "\u8F93\u51FA\u6458\u8981\uFF08\u7B80\u4F53\u4E2D\u6587\uFF0C\u6B63\u6587\u4E0D\u8D85\u8FC7 800 \u5B57\uFF09\uFF0C\u6309\u4EE5\u4E0B\u5C0F\u8282\u7EC4\u7EC7\uFF1A",
    "1. \u4EFB\u52A1\u76EE\u6807\uFF1A\u7528\u6237\u8981\u505A\u4EC0\u4E48\uFF1B",
    "2. \u5DF2\u5B8C\u6210\uFF1A\u7ED3\u8BBA\u3001\u5173\u952E\u6587\u4EF6\u4E0E\u8DEF\u5F84\u3001\u91CD\u8981\u4EE3\u7801\u51B3\u5B9A\uFF08\u4FDD\u7559\u7CBE\u786E\u7684\u6587\u4EF6\u540D/\u51FD\u6570\u540D/\u53C2\u6570\u540D\uFF09\uFF1B",
    "3. \u5F53\u524D\u72B6\u6001\uFF1A\u6700\u540E\u4E00\u6B65\u505A\u5230\u54EA\u3001\u6709\u65E0\u672A\u89E3\u51B3\u7684\u62A5\u9519\uFF1B",
    "4. \u4E0B\u4E00\u6B65\uFF1A\u5C1A\u672A\u5B8C\u6210\u7684\u4E8B\u9879\u3002",
    "\u53EA\u8F93\u51FA\u6458\u8981\u6B63\u6587\uFF0C\u4E0D\u8981\u5BD2\u6684\uFF1B\u4FE1\u606F\u4E0D\u8DB3\u7684\u5C0F\u8282\u53EF\u7701\u7565\u3002\u5DE5\u5177\u8C03\u7528\u7ED3\u679C\u53EA\u4FDD\u7559\u7ED3\u8BBA\uFF1B",
    "\u4E0D\u8981\u7F16\u9020\u8BB0\u5F55\u91CC\u6CA1\u6709\u7684\u5185\u5BB9\u3002"
  ), collapse = "\n")
}

# turns -> \u7EAF\u6587\u672C transcript\u3002
# \u6709\u6587\u672C\u7684\u8F6E\u6B21\u53D6\u5168\u6587\uFF1B@text \u4E3A\u7A7A\u7684\u8F6E\u6B21\uFF08\u5DE5\u5177\u8C03\u7528\u8F6E/\u5DE5\u5177\u7ED3\u679C\u8F6E\uFF09\u4ECE contents \u91CC
# \u6316\u7ED3\u6784\u75D5\u8FF9\uFF08ContentToolRequest / ContentToolResult \u7684\u540D\u5B57\u4E0E\u7ED3\u679C\u5934\uFF09\u3002
# \u5C3E\u90E8\u622A\u65AD\u5230 max_chars\uFF08\u8D85\u957F\u5BF9\u8BDD\u7684\u5934\u90E8\u4FE1\u606F\u5929\u7136\u88AB\u6458\u8981\u8986\u76D6\uFF0C\u4FDD\u5C3E\u90E8\u6700\u65B0\u8FDB\u5C55\uFF09\u3002
.dairh_turns_transcript <- function(turns, max_chars = 24000) {
  parts <- character(0)
  for (t in turns) {
    role <- tryCatch(as.character(t@role), error = function(e) "?")
    role <- if (length(role)) role[[1]] else "?"
    txt <- tryCatch(paste(as.character(t@text), collapse = "\n"), error = function(e) "")
    line <- NULL
    if (nzchar(trimws(txt %||% ""))) {
      line <- paste0(toupper(role), ": ", txt)
    } else {
      cs <- tryCatch(t@contents, error = function(e) NULL)
      seg <- character(0)
      for (c in if (is.list(cs)) cs else list()) {
        nm <- paste(class(c), collapse = "/")
        if (grepl("ToolRequest", nm, fixed = TRUE)) {
          aname <- tryCatch(as.character(c@name), error = function(e) "?")
          aargs <- tryCatch(paste(deparse(c@arguments), collapse = " "), error = function(e) "")
          seg <- c(seg, sprintf("[tool call] %s(%s)", aname, .dai_clip(aargs, 300)))
        } else if (grepl("ToolResult", nm, fixed = TRUE)) {
          v <- tryCatch(paste(as.character(c@value), collapse = " "), error = function(e) "")
          if (!nzchar(trimws(v))) v <- tryCatch(.dai_content_brief(c), error = function(e) "")
          seg <- c(seg, sprintf("[tool result] %s", .dai_clip(v, 300)))
        }
      }
      if (length(seg)) {
        line <- paste0(toupper(role), " (tool): ", paste(seg, collapse = " ; "))
      }
    }
    if (!is.null(line)) parts <- c(parts, line)
  }
  out <- paste(parts, collapse = "\n\n")
  .dai_clip(out, max_chars)
}

# \u6458\u8981\u751F\u6210\uFF08\u53EA\u8BFB\uFF1A\u4E0D\u52A8 client \u7684 turns/\u72B6\u6001\uFF1B\u5931\u8D25\u5411\u4E0A\u629B\uFF0C\u7531\u8C03\u7528\u65B9\u51B3\u5B9A\u5C55\u793A\uFF09\u3002
.dairh_compact_summary <- function(client, cfg = dairh_config_get(), max_chars = 24000) {
  turns <- client$get_turns()
  transcript <- .dairh_turns_transcript(turns, max_chars)
  if (!nzchar(trimws(transcript))) {
    return(list(ok = FALSE, msg = "\u5F53\u524D\u4F1A\u8BDD\u8FD8\u6CA1\u6709\u53EF\u538B\u7F29\u7684\u5BF9\u8BDD\u5185\u5BB9\u3002"))
  }
  summarizer <- dairh_client(cfg, system_prompt = .dairh_compact_prompt())
  summary <- summarizer$chat(paste0("\u8BF7\u538B\u7F29\u4EE5\u4E0B\u5BF9\u8BDD\u8BB0\u5F55\uFF1A\n\n", transcript))
  summary_text <- trimws(paste(as.character(summary), collapse = "\n"))
  if (!nzchar(summary_text)) {
    return(list(ok = FALSE, msg = "\u6458\u8981\u4E3A\u7A7A\uFF08\u6A21\u578B\u672A\u8FD4\u56DE\u5185\u5BB9\uFF09\uFF0C\u672A\u505A\u4EFB\u4F55\u4FEE\u6539\u3002"))
  }
  list(ok = TRUE, summary = summary_text, n_old = length(turns))
}

# \u91CD\u6C34\u5408 + \u786C\u9884\u7B97\u91CD\u7F6E + trace\u3002set_turns \u4FDD\u7559\u7CFB\u7EDF\u63D0\u793A\u8BCD\uFF08\u4E0E\u6E05\u7A7A\u5BF9\u8BDD\u540C\u8BED\u4E49\uFF09\u3002
# \u91CD\u6C34\u5408\u5F62\u6001\uFF1Auser(\u6458\u8981) + assistant(\u786E\u8BA4) \u4E24\u8F6E\u2014\u2014\u4FDD\u6301 user/assistant \u4EA4\u66FF\uFF0C
# \u9884\u7B97\u7684\u56DE\u5408\u68C0\u6D4B\u628A\u5B83\u5F53\u4E00\u8F6E\u5DF2\u56DE\u7B54\u7684\u5386\u53F2\u5BF9\u8BDD\uFF0C\u4E0B\u4E00\u6761\u771F\u5B9E\u7528\u6237\u6D88\u606F\u81EA\u7136\u5F00\u65B0\u56DE\u5408\u3002
.dairh_compact_apply <- function(client, summary, n_old = NA_integer_) {
  new_turns <- list(
    ellmer::Turn(
      role = "user",
      contents = list(ellmer::ContentText(text = paste0(
        "\u6B64\u524D\u5BF9\u8BDD\u5DF2\u5B8C\u6210\u538B\u7F29\uFF08\u539F\u59CB\u7EC6\u8282\u5DF2\u5F52\u6863\uFF09\uFF0C\u4EE5\u4E0B\u662F\u5DE5\u4F5C\u6458\u8981\uFF1A\n\n", summary
      )))
    ),
    ellmer::Turn(
      role = "assistant",
      contents = list(ellmer::ContentText(text = paste0(
        "\u6458\u8981\u5DF2\u52A0\u8F7D\uFF0C\u6211\u5DF2\u4E86\u89E3\u6B64\u524D\u4EFB\u52A1\u7684\u76EE\u6807\u3001\u8FDB\u5C55\u4E0E\u5173\u952E\u51B3\u5B9A\uFF0C\u53EF\u4EE5\u7EE7\u7EED\u63A8\u8FDB\u3002"
      )))
    )
  )
  client$set_turns(new_turns)
  st <- attr(client, ".dairh_state")
  if (is.environment(st)) {
    st$n_calls <- 0L
    st$last_user_n <- NA_integer_
    .dairh_trace_write(st, list(
      ts = format(Sys.time(), "%Y-%m-%d %H:%M:%OS3"),
      pid = Sys.getpid(),
      type = "compact",
      n_old = n_old,
      summary_chars = nchar(summary)
    ))
  }
  invisible(TRUE)
}

# \u4E00\u6B65\u5230\u4F4D\uFF08CLI / \u4E0E\u6D4B\u8BD5\u7528\uFF09\uFF1A\u6458\u8981 + \u5E94\u7528\u3002\u8FD4\u56DE list(ok, summary, n_old[, msg])\u3002
.dairh_compact_turns <- function(client, cfg = dairh_config_get(), max_chars = 24000) {
  s <- .dairh_compact_summary(client, cfg, max_chars)
  if (!isTRUE(s$ok)) return(s)
  .dairh_compact_apply(client, s$summary, s$n_old)
  s
}


# 0.8 \u538B\u7F29\u7684\u627E\u56DE\u4FDD\u9669\uFF1A\u628A\u5F53\u524D\u4F1A\u8BDD\u7684 shinychat \u5B58\u50A8\u4E09\u4EF6\u5957
#\uFF08record.json + turns.jsonl + ui.jsonl\uFF09\u6574\u6811\u590D\u5236\u4E3A\u300C\uFF08\u538B\u7F29\u524D\u5907\u4EFD\uFF09\u300D\u6761\u76EE\u3002
# new_chat \u662F"\u8BB0\u5F55\u539F\u5730\u91CD\u5F00"\u2014\u2014\u65E7\u8F6E\u6B21\u4E0D\u7559\u526F\u672C\uFF0C\u6CA1\u6709\u8FD9\u4E00\u6B65\u5C31\u6CA1\u6709\u627E\u56DE\u3002
# record.json \u6539\u5199 id/title \u7528 jsonlite \u5355\u6B21\u5F80\u8FD4 + \u5F62\u72B6\u6821\u9A8C\uFF08nodes/values
# \u6570\u91CF\u4E0E\u539F\u4EF6\u4E00\u81F4\u624D\u843D\u76D8\uFF0C\u9632 auto_unbox \u5F62\u53D8\uFF09\uFF1B\u5931\u8D25/\u65E0\u8BB0\u5F55\u8FD4\u56DE NULL\uFF0C
# \u8C03\u7528\u65B9\u8DF3\u8FC7\u5907\u4EFD\u7EE7\u7EED\u538B\u7F29\uFF08\u540E\u679C = \u65E7\u8F6E\u6B21\u4E0D\u53EF\u627E\u56DE\uFF0C\u4E0E\u65E0\u5907\u4EFD\u884C\u4E3A\u76F8\u540C\uFF09\u3002
.dairh_compact_backup_record <- function(dir = .dairh_history_dir()) {
  if (!dir.exists(dir)) return(NULL)
  recs <- list.files(dir, pattern = "^record[.]json$",
    recursive = TRUE, full.names = TRUE)
  if (!length(recs)) return(NULL)
  info <- file.info(recs)
  src_rec <- recs[order(info$mtime, decreasing = TRUE)][[1]] # \u6B63\u88AB\u5199\u5165\u7684\u5F53\u524D\u4F1A\u8BDD
  j <- tryCatch(jsonlite::fromJSON(src_rec, simplifyVector = FALSE),
                error = function(e) NULL)
  if (is.null(j) || !is.character(j$id) || !nzchar(j$id) ||
      !is.character(j$title) || !length(j$title)) return(NULL)
  src_dir <- dirname(src_rec)
  new_id <- paste0(j$id, sprintf("%06x", as.integer(format(Sys.time(), "%H%M%S"))))
  new_dir <- file.path(dirname(src_dir), new_id)
  if (!dir.create(new_dir)) return(NULL) # \u540C\u79D2\u91CD\u538B \u2192 \u76EE\u5F55\u5DF2\u5B58\u5728 \u2192 \u653E\u5F03\u5907\u4EFD
  # \u9010\u6587\u4EF6 readBin/writeBin \u5B57\u8282\u590D\u5236\uFF08file.copy \u9047 list.files \u7684 ./.. \u6DF7\u5165
  # \u4E0E\u591A\u6587\u4EF6\u5411\u91CF\u65F6\u5B9E\u6D4B\u4F1A\u4EA7\u51FA 0 \u5B57\u8282\u526F\u672C\u2014\u20140.8 \u4E8B\u6545\u590D\u76D8\u6362\u6389\u7684\uFF09\uFF1B\u590D\u5236\u540E
  # \u9010\u4E00\u5BF9\u5C3A\u5BF8\u65AD\u8A00\uFF0C\u4EFB\u4F55\u4E0D\u7B26\u5373\u653E\u5F03\u5907\u4EFD\uFF08\u8C03\u7528\u65B9\u7EE7\u7EED\u538B\u7F29\uFF0C\u4E0D\u963B\u65AD\uFF09\u3002
  files <- list.files(src_dir, full.names = TRUE)
  if (!length(files)) {
    unlink(new_dir, recursive = TRUE, force = TRUE)
    return(NULL)
  }
  ok <- tryCatch({
    for (f0 in files) {
      b <- readBin(f0, what = "raw", n = file.size(f0))
      con <- file(file.path(new_dir, basename(f0)), open = "wb")
      tryCatch({ writeBin(b, con) }, finally = close(con))
      if (file.size(file.path(new_dir, basename(f0))) != length(b)) return(FALSE)
    }
    TRUE
  }, error = function(e) FALSE)
  if (!identical(ok, TRUE)) {
    unlink(new_dir, recursive = TRUE, force = TRUE)
    return(NULL)
  }
  rec <- file.path(new_dir, "record.json")
  j$id <- new_id
  j$title <- paste0(j$title[[1]], "\uFF08\u538B\u7F29\u524D\u5907\u4EFD\uFF09")
  ok <- tryCatch({
    writeLines(jsonlite::toJSON(j, auto_unbox = TRUE, null = "null"),
               rec, useBytes = TRUE)
    v <- jsonlite::fromJSON(rec, simplifyVector = FALSE)
    length(v$nodes) == length(j$nodes) && length(v$values) == length(j$values)
  }, error = function(e) FALSE)
  if (!identical(ok, TRUE)) {
    unlink(new_dir, recursive = TRUE, force = TRUE)
    return(NULL)
  }
  new_dir
}
