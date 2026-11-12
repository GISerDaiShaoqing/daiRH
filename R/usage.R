# DaiRH token \u7528\u91CF\u65E5\u5FD7 ---------------------------------------------------------
# \u6BCF\u6B21\u6A21\u578B\u8BF7\u6C42\uFF08\u542B\u5DE5\u5177\u5FAA\u73AF\u7684\u6BCF\u6B21 round-trip\u3001\u4F1A\u8BDD\u8D77\u6807\u9898\u3001\u5B50\u4EE3\u7406\u3001\u538B\u7F29\u603B\u7ED3\u5668\uFF09
# \u8FFD\u52A0\u4E00\u884C jsonl \u5230 R_user_dir("daiRH","data")/usage/usage.jsonl\uFF0C
# \u8BB0\u8D26\u8BED\u4E49\u4E0E"\u6309\u8BF7\u6C42\u8BA1\u8D39"\u7684\u7F51\u5173\uFF08\u5982\u6309\u6B21\u8BA1\u8D39\u7684\u5957\u9910\uFF09\u5BF9\u9F50\u3002
# \u8BBE\u8BA1\u7EA6\u675F\uFF08\u5BF9\u8FED\u4EE3\u6700\u5C0F\u4FB5\u5165\uFF09\uFF1A
#   - \u53EA\u4F9D\u8D56\u54CD\u5E94\u91CC\u672C\u6765\u5C31\u6709\u7684\u4E1C\u897F\uFF08turn@tokens + \u6A21\u578B\u540D\uFF09\uFF0C\u4E0D\u78B0 harness \u5185\u90E8\u72B6\u6001\uFF1B
#   - \u5355\u4E00\u6F0F\u6597\uFF1Adairh_client() \u6784\u9020\u65F6\u7ECF ellmer \u7684 on_request_end \u56DE\u8C03\u6302\u4E0A\uFF0C
#     \u9762\u677F / CLI / \u5B50\u4EE3\u7406 / \u8D77\u6807\u9898\u5168\u90E8\u81EA\u52A8\u8986\u76D6\uFF0C\u5404\u5904\u96F6\u6539\u52A8\uFF1B
#   - \u65C1\u8DEF\uFF1A\u73AF\u5883\u53D8\u91CF DAIRH_USAGE_LOG=0 \u6574\u4F53\u5173\u95ED\uFF1B\u6D4B\u8BD5\u7528 options(daiRH.usage_dir=) \u6362\u76EE\u5F55\u3002
# \u5DF2\u77E5\u8FB9\u754C\uFF1A\u8BF7\u6C42\u51FA\u9519\u65F6 ellmer \u4E0D\u89E6\u53D1 on_request_end\uFF08\u9519\u8BEF\u8BF7\u6C42\u7F51\u5173\u4E5F\u4E0D\u8BA1\u8D39\uFF09\uFF0C
#   \u6545 ok=FALSE \u7684\u884C\u5B9E\u9645\u4E0D\u4F1A\u4EA7\u751F\uFF1B\u88AB\u53D6\u6D88\u7684\u8BF7\u6C42 turn@tokens \u4E3A NA\uFF0C\u6B64\u5904\u8DF3\u8FC7\u4E0D\u8BB0\u3002

.dairh_usage_dir <- function() {
  d <- getOption("daiRH.usage_dir")
  if (is.null(d) || !is.character(d) || !nzchar(d)) {
    d <- file.path(tools::R_user_dir("daiRH", "data"), "usage")
  }
  dir.create(d, recursive = TRUE, showWarnings = FALSE)
  d
}

# turn@tokens -> \u5951\u7EA6\u5B57\u6BB5\uFF08input / output / cache_read\uFF09\u3002
# ellmer \u8FD0\u884C\u65F6\u5F62\u6001\u662F numeric(3) = c(input, output, cached_input)
# \uFF08AssistantTurn \u9ED8\u8BA4 c(NA, NA, NA)\u2014\u2014\u88AB\u53D6\u6D88\u7684\u8BF7\u6C42\u5373\u6B64\u5F62\u6001\uFF0C\u89E3\u6790\u540E\u5168 0 \u7531\u8C03\u7528\u65B9\u8DF3\u8FC7\uFF09\u3002
# \u547D\u540D\u4E0E\u5916\u90E8\u76D1\u6D4B\u5DE5\u5177\u7684\u5F52\u4E00\u5316\u53E3\u5F84\u4E00\u81F4\uFF1Acache_read \u5373\u7F13\u5B58\u547D\u4E2D\u90E8\u5206
# \uFF08\u7F51\u5173\u4FA7\u65E0\u8BBA\u53EB prompt_cache_hit_tokens \u8FD8\u662F cached_tokens\uFF0Cellmer \u5DF2\u5F52\u4E00\u4E3A\u7B2C 3 \u4E2A\u5206\u91CF\uFF09\u3002
# \u7F51\u5173\u65E0\u72EC\u7ACB cache_write \u5B57\u6BB5\uFF0C\u7559\u7A7A\u7531\u76D1\u6D4B\u5DE5\u5177\u81EA\u884C\u7B97 input_uncached\u3002
.dairh_usage_resolve <- function(tokens) {
  if (is.null(tokens)) return(NULL)
  if (is.numeric(tokens) && length(tokens) == 3L) {
    v <- suppressWarnings(as.numeric(tokens))
    v[!is.finite(v) | v < 0] <- 0
    return(list(input = v[[1]], output = v[[2]], cache_read = v[[3]]))
  }
  # \u9632\u5FA1\u5206\u652F\uFF1A\u547D\u540D list \u5F62\u6001\uFF08\u6D4B\u8BD5\u5047\u4EF6 / \u672A\u6765 ellmer \u6539\u7ED3\u6784\u65F6\u515C\u5E95\uFF09
  grab <- function(field) {
    v <- tryCatch(
      if (!is.null(tokens[[field]])) tokens[[field]] else NULL,
      error = function(e) NULL
    )
    v <- suppressWarnings(as.numeric(if (is.null(v)) NA else v[[1]]))
    if (length(v) != 1L || is.na(v) || !is.finite(v) || v < 0) 0 else v
  }
  list(
    input = grab("input"),
    output = grab("output"),
    cache_read = grab("cached_input")
  )
}

# \u8FFD\u52A0\u4E00\u884C\u5230 usage.jsonl\uFF08\u4E8C\u8FDB\u5236\u8FFD\u52A0\u5199\uFF0C\u907F\u5F00\u672C\u5730 ASCII locale \u7684\u7F16\u7801\u8F6C\u6362\u5751\uFF1B
# \u4E0E trace \u540C\u6B3E\u5199\u6CD5\uFF09\u3002\u4EFB\u4F55\u5931\u8D25\u9759\u9ED8\u2014\u2014\u8BB0\u8D26\u7EDD\u4E0D\u5E72\u6270\u5BF9\u8BDD\u3002
.dairh_usage_log <- function(model, usage, ok = TRUE) {
  if (identical(Sys.getenv("DAIRH_USAGE_LOG"), "0")) return(invisible(FALSE))
  fields <- list(
    ts = format(Sys.time(), "%Y-%m-%d %H:%M:%OS3"),
    pid = Sys.getpid(),
    source = "daiRH",
    model = as.character(model %||% ""),
    ok = isTRUE(ok)
  )
  fields <- c(fields, usage)
  # cost \u53D6\u4E0D\u5230\u65F6\u662F NULL\uFF1AJSON \u91CC\u7559\u7A7A\u8BE5\u5B57\u6BB5\uFF08cost=NA \u5BF9\u76D1\u6D4B\u5DE5\u5177\u662F\u566A\u58F0\uFF09
  fields <- fields[!vapply(fields, is.null, logical(1))]
  line <- tryCatch(
    jsonlite::toJSON(fields, auto_unbox = TRUE, null = "null"),
    error = function(e) NULL
  )
  if (is.null(line) || !is.character(line) || !length(line)) return(invisible(FALSE))
  con <- tryCatch(file(file.path(.dairh_usage_dir(), "usage.jsonl"), open = "ab"),
    error = function(e) NULL
  )
  if (is.null(con)) return(invisible(FALSE))
  on.exit(close(con), add = TRUE)
  tryCatch(
    writeBin(charToRaw(paste0(enc2utf8(line), "\n")), con),
    error = function(e) invisible(FALSE)
  )
  invisible(TRUE)
}

# token \u6570\u5C55\u793A\u683C\u5F0F\u5316\uFF08\u9762\u677F header \u7528\uFF09\uFF1A0/999/1.2 \u4E07\u5185\u539F\u6837\uFF0C1e4 \u8D77\u8FDB k\uFF0C1e6 \u8D77\u8FDB M
.dai_fmt_tokens <- function(n) {
  n <- suppressWarnings(as.numeric(n))
  if (length(n) != 1L || is.na(n) || !is.finite(n)) return("0")
  if (n >= 1e6) sprintf("%.1fM", n / 1e6)
  else if (n >= 1e4) sprintf("%.1fk", n / 1e3)
  else sprintf("%d", as.integer(round(n)))
}

# \u79D2\u6570 -> "49 \u5206 51.6 \u79D2" / "12.3 \u79D2"\uFF080.7 \u9762\u677F\u5DE5\u4F5C\u65F6\u957F\u7528\uFF09
.dai_fmt_dur <- function(secs) {
  secs <- suppressWarnings(as.numeric(secs))
  if (length(secs) != 1L || is.na(secs) || !is.finite(secs) || secs < 0) return("0 \u79D2")
  if (secs >= 3600) {
    h <- floor(secs / 3600)
    m <- floor((secs - h * 3600) / 60)
    sprintf("%d \u5C0F\u65F6 %d \u5206 %.0f \u79D2", h, m, secs - h * 3600 - m * 60)
  } else if (secs >= 60) {
    m <- floor(secs / 60)
    sprintf("%d \u5206 %.1f \u79D2", m, secs - m * 60)
  } else {
    sprintf("%.1f \u79D2", secs)
  }
}

# \u552F\u4E00\u6302\u70B9\uFF1Adairh_client() \u6784\u9020\u5B8C\u6210\u540E\u8C03\u7528\u3002on_request_start \u8BB0\u8BF7\u6C42\u8D77\u70B9\uFF08\u542B\u5DE5\u5177\u5FAA\u73AF
# \u6BCF\u4E00\u8DF3\uFF09\uFF0Con_request_end \u6536\u521A\u8FD4\u56DE\u7684 assistant turn\uFF1A\u7B97 duration_s \u4E0E tok_per_s
# \uFF08\u8F93\u51FA token / \u8BF7\u6C42\u65F6\u957F\uFF09\u5199\u5165 jsonl\uFF0C\u5E76\u628A (turn, tok_per_s) \u5B58\u8FDB rate env
# \uFF08attr(client,".dairh_rate")\uFF09\u4F9B\u9762\u677F\u72B6\u6001\u680F\u663E\u793A\u3002
# \u53D6\u6D88\u7684\u8BF7\u6C42\u662F AssistantPartialTurn\uFF08tokens \u4E3A NA\uFF09\u2014\u2014resolve \u540E\u5168 0\uFF0C\u76F4\u63A5\u8DF3\u8FC7
# \uFF08\u4E0D\u8BA1\u8D39\u7684\u4E0D\u8BB0\uFF0C\u901F\u5EA6\u4E5F\u4E0D\u5237\u65B0\uFF09\u3002\u5DF2\u77E5\u8FD1\u4F3C\uFF1A\u8D77\u6807\u9898\u8D70 client$clone()\uFF0C\u56DE\u8C03\u6309\u5F15\u7528
# \u5171\u4EAB\uFF0C\u6807\u9898\u8BF7\u6C42\u4E5F\u4F1A\u8D70\u5230\u8FD9\u91CC\u2014\u2014\u9762\u677F\u4FA7\u6309 turn \u5BF9\u8C61\u4E00\u81F4\u6027\u8FC7\u6EE4\u663E\u793A\uFF0Cjsonl \u7167\u5B9E\u8BB0\u3002
.dairh_usage_install <- function(client, model) {
  if (identical(Sys.getenv("DAIRH_USAGE_LOG"), "0")) return(client)
  renv <- new.env(parent = emptyenv())
  renv$t0 <- Sys.time() # start \u56DE\u8C03\u6CA1\u6302\u4E0A\u4E5F\u6709\u7684\u515C\u5E95\u8D77\u70B9
  renv$last <- NULL
  tryCatch(
    client$on_request_start(function(turns) {
      renv$t0 <- Sys.time()
      invisible(NULL)
    }),
    error = function(e) NULL
  )
  tryCatch(
    client$on_request_end(function(turn) {
      dur <- as.numeric(difftime(Sys.time(), renv$t0, units = "secs"))
      if (!is.finite(dur) || dur < 0) dur <- NA_real_
      tk <- tryCatch(turn@tokens, error = function(e) NULL)
      usage <- .dairh_usage_resolve(tk)
      if (is.null(usage)) return(invisible(FALSE))
      if (usage$input == 0 && usage$output == 0) return(invisible(FALSE))
      # tok/s\uFF1A\u8FC7\u77ED\u8BF7\u6C42\uFF08<0.05s\uFF09\u4E0D\u53EF\u4FE1\uFF0C\u4E0D\u5199\u4E0D\u5B58
      rate <- if (is.finite(dur) && dur >= 0.05 && usage$output > 0) {
        round(usage$output / dur, 1)
      } else NULL
      renv$last <- list(turn = turn, tok_per_s = rate, duration_s = dur)
      # @cost\uFF1A\u6709\u5B9A\u4EF7\u8868\u7684\u7AEF\u70B9\u624D\u975E NA\uFF1B\u53D6\u4E0D\u5230\u5C31\u4E0D\u5199\u8BE5\u5B57\u6BB5
      cost <- tryCatch({
        cv <- suppressWarnings(as.numeric(turn@cost)[[1]])
        if (is.finite(cv) && cv > 0) cv else NULL
      }, error = function(e) NULL)
      .dairh_usage_log(model, c(usage, list(
        cost = cost,
        duration_s = if (is.finite(dur)) round(dur, 3) else NULL,
        tok_per_s = rate
      )), ok = TRUE)
    }),
    error = function(e) NULL
  )
  attr(client, ".dairh_rate") <- renv
  client
}

# 0.8 \u9762\u677F"\u4E0A\u4E0B\u6587\u5360\u7528"\u53D6\u6570\uFF08\u7EAF\u51FD\u6570\uFF0C\u4FBF\u4E8E\u6D4B\u8BD5\uFF09\uFF1A
# \u7F13\u5B58\u8BA1\u8D39\u7F51\u5173\u628A\u5B8C\u6574 prompt \u62C6\u6210\u4E24\u7B14\u8BB0\u8D26\u2014\u2014input = \u672A\u547D\u4E2D\u589E\u91CF\uFF0C
# cache_read = \u7F13\u5B58\u547D\u4E2D\uFF080.8 \u5B9E\u6D4B\uFF1Aprompt_tokens \u53EA\u62A5\u589E\u91CF\uFF0C\u547D\u4E2D\u90E8\u5206\u5355\u5217\u7B2C\u4E09\u5206\u91CF\uFF09\u3002
# \u7F13\u5B58\u547D\u4E2D\u7684\u90E8\u5206\u7167\u6837\u5360\u7740\u4E0A\u4E0B\u6587\u7A97\u53E3\uFF0C\u6545\u5360\u7528 = input + cache_read\u3002
# tokens \u4E3A numeric(3)\uFF08ellmer \u8FD0\u884C\u65F6\u5F62\u6001\uFF09\u2192 v1+v3\uFF1Bnumeric(2)\uFF08\u65E7\u5F62\u6001/\u9632\u5FA1\uFF09\u2192 v1\uFF1B
# \u5168\u96F6/\u4E0D\u53EF\u7528 \u2192 NULL\uFF1Btokens \u4E0D\u53EF\u7528\u4E14\u7ED9\u4E86 get_tokens \u6570\u636E\u6846 \u2192 \u672B\u884C input(+cached_input) \u56DE\u9000\u3002
.dairh_ctx_used <- function(tokens, tb = NULL) {
  v <- suppressWarnings(as.numeric(tokens))
  v <- v[is.finite(v) & v >= 0]
  if (length(v) >= 3L && (v[[1]] > 0 || v[[3]] > 0)) return(v[[1]] + v[[3]])
  if (length(v) >= 1L && v[[1]] > 0) return(v[[1]])
  if (is.data.frame(tb) && nrow(tb) > 0) {
    used <- suppressWarnings(utils::tail(as.numeric(tb$input), 1))
    if ("cached_input" %in% names(tb)) {
      cr <- suppressWarnings(utils::tail(as.numeric(tb$cached_input), 1))
      if (length(cr) == 1L && is.finite(cr) && cr > 0) used <- used + cr
    }
    if (length(used) == 1L && is.finite(used) && used > 0) return(used)
  }
  NULL
}

# 0.8 \u538B\u7F29/\u6E05\u7A7A\u540E\u7684"\u4E0A\u4E0B\u6587\u5360\u7528"\u4F30\u7B97\uFF08\u6CA1\u6709\u771F\u5B9E\u8BF7\u6C42\u53EF\u4F9D\u636E\u65F6\uFF09\uFF1A
# \u7CFB\u7EDF\u63D0\u793A + \u5168\u90E8\u8F6E\u6B21\u6587\u672C\u7684\u5B57\u7B26\u6570 x 0.4\u2014\u2014\u7C97\u4F30\uFF08\u4E2D\u82F1\u6DF7\u6392\u7ECF\u9A8C\u7CFB\u6570\uFF09\uFF0C
# \u72B6\u6001\u680F\u4F1A\u6807\u6CE8"\u4F30\u7B97"\uFF1B\u4E0B\u4E00\u6B21\u771F\u5B9E\u8BF7\u6C42\u7684 input + cache_read \u81EA\u52A8\u53D6\u4EE3\u5B83\u3002
.dai_est_ctx <- function(client) {
  if (is.null(client)) return(NULL)
  tryCatch({
    n <- nchar(client$get_system_prompt() %||% "", type = "chars")
    for (t in client$get_turns()) {
      txt <- tryCatch(paste(as.character(t@text), collapse = "\n"), error = function(e) "")
      if (is.list(t@contents %||% NULL)) {
        for (cc in t@contents) {
          v <- tryCatch(paste(as.character(cc@text %||% cc@value), collapse = "\n"),
                        error = function(e) "")
          txt <- paste(txt, v)
        }
      }
      n <- n + nchar(txt, type = "chars")
    }
    if (n <= 0) return(NULL)
    round(n * 0.4)
  }, error = function(e) NULL)
}
