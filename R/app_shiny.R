# DaiRH Shiny \u804A\u5929\u9762\u677F --------------------------------------------------------

# \u9762\u677F\u4E3B\u804A\u5929\uFF08shinychat 0.5+ \u7684 chat_ui / chat_server\uFF0C\u540C\u547D\u540D\u7A7A\u95F4\u76F4\u8FDE\uFF09\u3002
# \u65E7\u7248 chat_mod_ui \u4F1A\u628A DOM \u5305\u8FDB NS("chat") \u547D\u540D\u7A7A\u95F4\uFF0C\u6240\u4EE5\u90A3\u65F6\u5FC5\u987B\u5728\u540C\u540D
# moduleServer \u91CC\u8C03 update_chat_user_input \u624D\u80FD\u547D\u4E2D DOM\u30020.5 \u8D77\u6539\u7528
# chat_ui + chat_server\uFF08\u8DD1\u5728\u8C03\u7528\u65B9\u4F5C\u7528\u57DF\uFF0C\u4E0D\u518D\u5305\u547D\u540D\u7A7A\u95F4\uFF09\uFF0C\u5168\u90E8\u804A\u5929
# \u8F85\u52A9\u8C03\u7528\u5728\u4E3B\u4F1A\u8BDD\u4F5C\u7528\u57DF\u76F4\u63A5\u8FDB\u884C\uFF0C\u6A21\u5757\u8F6C\u63A5\u5C42\u5DF2\u6574\u4F53\u79FB\u9664\u3002

# \u95EE\u5019\u8BED\u91CC\u7684\u7F16\u8F91\u5668\u4E0A\u4E0B\u6587\u72B6\u6001\u884C\uFF08\u4EC5\u540E\u53F0\u6A21\u5F0F\uFF09\uFF1A\u5FEB\u7167\u5F0F\u67B6\u6784\u4E0B
# \u62A5\u544A\u6700\u65B0\u5FEB\u7167\u65F6\u95F4\u4E0E\u5237\u65B0\u65B9\u5F0F\uFF0C\u8BA9"\u4E3A\u4EC0\u4E48\u62FF\u4E0D\u5230\u9009\u533A"\u4E00\u773C\u53EF\u89C1\u3002
# \u9762\u677F"\u6E05\u7A7A\u5BF9\u8BDD"\u7684\u4F1A\u8BDD\u91CD\u7F6E\uFF1A\u786C\u9884\u7B97\u8BA1\u6570\u5F52\u96F6\uFF08\u4E0D\u91CD\u5EFA client\uFF0C
# \u4E0D\u5F80\u5B50\u8FDB\u7A0B\u501F\u5176\u5B83\u901A\u9053\u518D\u53D1\u6570\u636E\uFF09\uFF0C\u6E05\u6A21\u578B\u5386\u53F2\uFF08\u5B9E\u6D4B
# client$set_turns(list()) \u4FDD\u7559\u7CFB\u7EDF\u63D0\u793A\uFF09\uFF1Btrace \u7EE7\u7EED\u540C\u4E00\u6587\u4EF6\u8FFD\u52A0
# session_reset \u8BB0\u5F55\u3002
.dai_reset_agent_state <- function(client) {
  st <- attr(client, ".dairh_state")
  if (is.environment(st)) {
    st$n_calls <- 0L
    st$last_user_n <- NA_integer_
    .dairh_trace_write(st, list(
      ts = format(Sys.time(), "%Y-%m-%d %H:%M:%OS3"),
      pid = Sys.getpid(),
      type = "session_reset"
    ))
  }
  client$set_turns(list())
  invisible(TRUE)
}

.dairh_greeting_bridge_line <- function() {
  if (!identical(getOption("daiRH.daemon_mode"), TRUE)) return("")
  j <- .dairh_bridge_snapshot()
  if (!is.null(j) && !is.null(j$time)) {
    has_ctx <- nzchar(as.character(j$context %||% ""))
    paste0(
      "\n\n**\u7F16\u8F91\u5668\u4E0A\u4E0B\u6587**\uFF1A\u5FEB\u7167\u5F0F \u2705 \u6700\u8FD1\u5FEB\u7167 ",
      j$time,
      if (!has_ctx) "\uFF08\u5F53\u65F6\u6CA1\u6709\u53EF\u8BFB\u7684\u6D3B\u52A8\u6587\u4EF6\uFF1B\u5728\u63A7\u5236\u53F0\u8FD0\u884C\u4EFB\u610F\u4E00\u884C\u4EE3\u7801\u5237\u65B0\uFF0C\u6216\u7528\u52A0\u8F7D\u9879 daiRH Send Selection \u76F4\u53D1\u9009\u4E2D\u4EE3\u7801\uFF09",
      if (has_ctx) "\uFF08\u968F\u63A7\u5236\u53F0\u6D3B\u52A8\u81EA\u52A8\u5237\u65B0\uFF1B\u7A7A\u56DE\u8F66\u4E0D\u4E00\u5B9A\u89E6\u53D1\u2014\u2014\u9009\u533A\u8BB2\u89E3\u63A8\u8350\u52A0\u8F7D\u9879 daiRH Send Selection\uFF09"
    )
  } else {
    paste0(
      "\n\n**\u7F16\u8F91\u5668\u4E0A\u4E0B\u6587**\uFF1A\u5C1A\u65E0\u5FEB\u7167\uFF08\u5728 RStudio \u63A7\u5236\u53F0\u8FD0\u884C\u4EFB\u610F\u4E00\u884C\u4EE3\u7801\u540E\u81EA\u52A8\u751F\u6210\uFF09"
    )
  }
}

# \u9762\u677F\u4E3B\u9898 CSS\uFF08\u6DE1\u5F69\u745A\u7483\uFF1A\u80CC\u666F\u56FE\u5C42/\u73BB\u7483\u6807\u9898/\u9762\u677F\u82AF\u7247\u6309\u94AE/\u6DE1\u5F69\u6C14\u6CE1\uFF1B
# \u80CC\u666F\u9ED8\u8BA4\u5185\u7F6E\u591C\u6A31\uFF0Ccfg$bg_image \u53EF\u6362\uFF09
# \u4F1A\u8BDD\u6301\u4E45\u5316\uFF08shinychat 0.5 history \u62BD\u5C49\uFF09\uFF1A\u4EC5\u540E\u53F0\u9762\u677F\u542F\u7528\uFF08daemon_mode \u95F8\uFF09\u3002
# - \u5B58\u50A8\u76EE\u5F55\u7528 R_user_dir("daiRH","data")\uFF08\u4E0E config/cache \u540C\u65CF\uFF0C\u4E0D\u8FDB\u9879\u76EE\u76EE\u5F55\uFF09\uFF1B
# - scope \u56FA\u5B9A "daiRH"\uFF1A\u9762\u677F\u6BCF\u6B21\u542F\u52A8\u7AEF\u53E3\u968F\u673A\uFF08origin \u53D8 \u2192 localStorage \u6D4F\u89C8\u5668
#   \u4EE4\u724C\u53D8\uFF09\uFF0C\u4E0D\u56FA\u5B9A scope \u7684\u8BDD\u62BD\u5C49\u4E0E\u81EA\u52A8\u6062\u590D\u90FD\u4F1A\u968F\u7AEF\u53E3\u6F02\u79FB\u800C\u6E05\u96F6\uFF1B
# - title="auto" \u4F1A\u5728\u7B2C 2 \u6B21\u56DE\u590D\u540E\u514B\u9686 client \u591A\u53D1\u4E00\u6B21\u8C03\u7528\u7ED9\u4F1A\u8BDD\u8D77\u6807\u9898\uFF0C
#   cfg$history_title \u53EF\u5173\u3002
# 0.9 \u8F7B\u91CF\u6A21\u578B\u8D77\u6807\u9898\uFF1Atitle_model \u975E\u7A7A\u4E14\u4E0D\u540C\u4E8E\u4E3B\u6A21\u578B\u65F6\u6362\u5B83\u8D77\u6807\u9898\uFF08\u7701\u4E3B\u6A21\u578B\u8D26\uFF09\uFF0C
# \u5426\u5219\u4FDD\u6301 shinychat \u9ED8\u8BA4\uFF08\u514B\u9686\u4E3B\u5BF9\u8BDD\uFF09\u3002\u6807\u9898\u8BF7\u6C42\u540C\u6837\u7ECF dairh_client()
# \u8FDB\u7528\u91CF\u6F0F\u6597\uFF0C\u8D26\u672C model \u5B57\u6BB5\u8BB0 title_model\uFF0C\u5916\u90E8\u76D1\u6D4B\u5DE5\u5177\u53EF\u6309\u6A21\u578B\u5206\u8D26\u3002
# \u6807\u9898\u4E0D\u9700\u8981\u601D\u8003\uFF1Areasoning_effort \u5F3A\u5236\u7F6E\u7A7A\u3002\u540C\u6B65\u8C03\u7528\u4F1A\u77ED\u6682\u5360\u7528\u9762\u677F\u4E8B\u4EF6\u5FAA\u73AF\uFF0C
# \u6807\u9898\u8F93\u51FA\u53EA\u6709\u51E0\u5341 token\uFF0C\u53EF\u63A5\u53D7\uFF1B\u5931\u8D25\u65F6\u56DE\u9000 shinychat \u7684\u5178\u578B\u56DE\u9000\u6807\u9898\u3002
.daiRH_TITLE_PROMPT <- paste(
  "You title chat conversations.",
  "Reply with ONLY a short title for the conversation excerpt the user provides:",
  "at most 6 words, no quotes, no trailing punctuation."
)

# \u6807\u9898\u6E05\u6D17\uFF1A\u53BB\u9996\u5C3E\u5F15\u53F7/\u6807\u70B9\u3001\u6298\u53E0\u7A7A\u767D\u3001\u9650\u957F\u3002
.dairh_title_norm <- function(s) {
  s <- trimws(gsub("\\s+", " ", paste(as.character(s %||% ""), collapse = " ")))
  s <- gsub("^[\"'`]+|[\"'`]+$", "", s)
  s <- sub("[[:punct:][:space:]]+$", "", s)
  s <- trimws(s)
  if (nchar(s, type = "chars") > 60) s <- paste0(substr(s, 1L, 57L), "...")
  s
}

# \u53D6\u7B2C\u4E00\u7EC4\u7528\u6237/\u52A9\u624B\u5BF9\u8BDD\u505A\u6458\u8981\uFF08\u4ECE client \u7684 turns \u62BD\u6587\u672C\uFF0C\u4E0D\u78B0 shinychat \u5185\u90E8\u7ED3\u6784\uFF09\u3002
.dairh_title_excerpt <- function(turns, cap = 500) {
  if (!is.list(turns)) return(NULL)
  grab <- function(t) {
    txt <- tryCatch(
      trimws(paste(as.character(t@text %||% ""), collapse = " ")),
      error = function(e) ""
    )
    if (!nzchar(txt) && is.list(t@contents %||% NULL)) {
      txt <- trimws(paste(
        vapply(t@contents, function(cc) {
          tryCatch(
            paste(as.character(cc@text %||% cc@value %||% ""), collapse = " "),
            error = function(e) ""
          )
        }, character(1)),
        collapse = " "
      ))
    }
    txt
  }
  u <- NULL
  a <- NULL
  for (t in turns) {
    txt <- grab(t)
    if (!nzchar(txt)) next
    role <- tryCatch(t@role, error = function(e) "")
    if (identical(role, "user") && is.null(u)) {
      u <- txt
    } else if (identical(role, "assistant") && !is.null(u) && is.null(a)) {
      a <- txt
    }
  }
  if (is.null(u)) return(NULL)
  clip <- function(s) {
    if (nchar(s, type = "chars") > cap) paste0(substr(s, 1L, cap - 3L), "...") else s
  }
  paste0(
    "user: ", clip(u),
    if (!is.null(a)) paste0("\n\nassistant: ", clip(a)) else ""
  )
}

# \u8D77\u6807\u9898\u4E13\u7528\u8F7B\u91CF\u5BA2\u6237\u7AEF\uFF1A\u6362\u6A21\u578B\u3001\u5173\u601D\u8003\u5F3A\u5EA6\uFF0C\u8D70 dairh_client()\uFF08\u542B\u7528\u91CF\u6F0F\u6597\uFF09\u3002
.dairh_title_client <- function(cfg) {
  tm <- trimws(as.character(cfg$title_model %||% ""))
  if (!nzchar(tm) || identical(tm, cfg$model %||% "")) return(NULL)
  cfg2 <- cfg
  cfg2$model <- tm
  cfg2$reasoning_effort <- ""
  tryCatch(dairh_client(cfg2, system_prompt = .daiRH_TITLE_PROMPT), error = function(e) NULL)
}

# title \u53C2\u6570\u4E09\u6001\uFF1ANULL = \u5173\uFF1B"auto" = \u9ED8\u8BA4\u514B\u9686\u4E3B\u5BF9\u8BDD\uFF1Bfunction = \u81EA\u5B9A\u4E49\uFF08shinychat \u76F4\u63A5\u652F\u6301\uFF09\u3002
.dairh_title_fn <- function(cfg, client) {
  if (!isTRUE(cfg$history_title)) return(NULL)
  tc <- .dairh_title_client(cfg)
  if (is.null(tc)) return("auto")
  function(recorded_turns) {
    tryCatch({
      ex <- .dairh_title_excerpt(
        tryCatch(client$get_turns(), error = function(e) NULL)
      )
      if (is.null(ex)) return(NULL)
      .dairh_title_norm(tryCatch(tc$chat(ex), error = function(e) NULL) %||% "")
    }, error = function(e) NULL)
  }
}

.dairh_history_dir <- function(cfg = dairh_config_get()) {
  # 0.5 \u8D77\u53EF\u7ECF config.json \u7684 history_dir \u81EA\u5B9A\u4E49\uFF08\u7559\u7A7A = \u9ED8\u8BA4\u7528\u6237\u6570\u636E\u76EE\u5F55\uFF09\uFF1B
  # \u6539\u52A8\u540E\u65E7\u4F1A\u8BDD\u4E0D\u4F1A\u4E22\u2014\u2014\u53EA\u662F\u62BD\u5C49\u6307\u5411\u4E86\u65B0\u76EE\u5F55\u3002
  d <- trimws(as.character(cfg$history_dir %||% ""))
  if (nzchar(d)) d else file.path(tools::R_user_dir("daiRH", "data"), "conversations")
}

.dairh_history_enabled <- function(cfg) {
  isTRUE(cfg$history) && identical(getOption("daiRH.daemon_mode"), TRUE)
}

.dairh_history_options <- function(cfg, client = NULL) {
  if (!.dairh_history_enabled(cfg)) return(FALSE)
  shinychat::history_options(
    store = shinychat::FileConversationStore$new(.dairh_history_dir(cfg)),
    scope = "daiRH",
    title = .dairh_title_fn(cfg, client)
  )
}

# \u6253\u5F00\u9762\u677F\u65F6\u81EA\u52A8\u7EED\u63A5\u6700\u8FD1\u4E00\u6B21\u4F1A\u8BDD\uFF1A\u76F4\u63A5\u626B store \u76EE\u5F55\u91CC\u7684 record.json
# \uFF08\u4E0D\u78B0 shinychat \u5185\u90E8 API\uFF09\uFF0C\u53D6 mtime \u6700\u65B0\u7684\u5408\u6CD5 id\uFF1B\u7A7A\u5E93/\u76EE\u5F55\u4E0D\u5B58\u5728 \u2192 NULL\u3002
# \u8D70\u5B98\u65B9\u8F93\u5165\u901A\u9053 _history_select \u89E6\u53D1\uFF0Cshinychat \u5DF2\u81EA\u884C\u6062\u590D\u8FC7\u5219\u8C03\u7528\u65B9\u8DF3\u8FC7\u3002
.dairh_history_latest_id <- function(dir = .dairh_history_dir()) {
  recs <- list.files(dir, pattern = "^record[.]json$",
    recursive = TRUE, full.names = TRUE)
  if (!length(recs)) return(NULL)
  info <- file.info(recs)
  recs <- recs[order(info$mtime, decreasing = TRUE)]
  for (p in recs) {
    r <- tryCatch(jsonlite::fromJSON(p, simplifyVector = FALSE),
      error = function(e) NULL)
    id <- r$id
    if (is.character(id) && nzchar(id)) return(id)
  }
  NULL
}

.dai_panel_css <- function(history = FALSE, panel = FALSE) {
  paste0(
  "
  body {
    background: linear-gradient(160deg,#fbfaff 0%,#f3f3ff 48%,#f7fcff 100%);
    min-height: 100vh;
  }
  .dai-bg-layer {
    position: fixed; inset: 0; z-index: 0;
    background-position: center; background-size: cover; background-repeat: no-repeat;
    opacity: .34; pointer-events: none;
  }
  .dai-wrap { position: relative; z-index: 1; }
  .dai-mascot { filter: drop-shadow(0 2px 3px rgba(120,110,240,.25)); }
  .dai-spin {
    display: inline-block; width: 16px; height: 16px; margin-right: 8px;
    border: 3px solid #dcdcf7; border-top-color: #6366f1; border-radius: 50%;
    animation: dai-spin .9s linear infinite; vertical-align: -3px;
  }
  @keyframes dai-spin { to { transform: rotate(360deg); } }
  .dai-head {
    display: flex; align-items: center; gap: 10px;
    background: rgba(255,255,255,.72);
    backdrop-filter: blur(6px);
    border: 1px solid #ebe9fc; border-radius: 16px;
    padding: 8px 14px;
    box-shadow: 0 4px 18px rgba(110,102,240,.08);
    margin-bottom: 8px;
  }
  .dai-head .dai-title {
    font-weight: 800; font-size: 17px; letter-spacing: .5px;
    display: flex; align-items: center; gap: 8px;
    background: linear-gradient(90deg,#6366f1,#c084fc 55%,#38bdf8);
    -webkit-background-clip: text; background-clip: text;
    -webkit-text-fill-color: transparent; color: #6366f1;
  }
  .dai-head .dai-pill {
    background: #eef0ff; border: 1px solid #dcdcfa;
    border-radius: 999px; padding: 2px 12px; font-size: 12px; color: #5556c9;
  }
  .dai-head .dai-sub { color: #5556c9; }
  .dai-tok { color: #7c86e0; font-size: 12px; white-space: nowrap; }
  .dai-ctx-hot { color: #e8590c; font-weight: 600; }
  /* 0.6 \u5E95\u90E8\u72B6\u6001\u680F\uFF1A\u4F1A\u8BDD\u72B6\u6001\uFF08provider\u00B7\u6A21\u578B\u00B7\u5DE5\u5177 / token \u8BA1\u91CF / \u538B\u7F29\uFF09 */
  .dai-foot {
    display: flex; flex-wrap: wrap; align-items: center; gap: 4px 12px;
    margin: 6px 2px 0 2px; padding: 0 6px;
    font-size: 12px;
  }
  .dai-foot .flex-spacer { flex: 1; }
  .dai-foot .action-link, .dai-foot .btn-link { color: #8b8fd8 !important; font-size: 12px; }
  .dai-foot .action-link:hover .fa-compress { color: #6366f1; }
  .dai-head .flex-spacer { flex: 1; }
  .dai-head .action-link, .dai-head .btn-link { color: #9c9dd6 !important; }
  .dai-head .action-link:hover .fa-gear { transform: rotate(40deg); color: #6366f1; }
  .dai-head .fa-gear { transition: transform .2s ease; }
  /* 0.7 \u6A21\u5F0F\u70ED\u5207\u6362\u6309\u94AE\uFF08\u6784\u5EFA/\u8BA1\u5212\uFF09\uFF1A\u7D27\u51D1\u5706\u89D2\uFF0C\u968F\u72B6\u6001\u6362\u56FE\u6807\u6362\u5B57 */
  .dai-head .dai-mode-btn {
    font-size: 12px; padding: 1px 10px; line-height: 18px;
    border-radius: 999px; border: 1px solid #dcdcfa;
    background: #eef0ff; color: #5556c9;
  }
  .dai-head .dai-mode-btn:hover { border-color: #6366f1; color: #6366f1; }
  .dai-quick {
    display: flex; flex-wrap: nowrap; overflow-x: auto; gap: 4px;
    margin: 0 2px 10px 2px; padding: 2px 2px 4px;
    scrollbar-width: thin;
  }
  .dai-quick::-webkit-scrollbar { height: 5px; }
  .dai-quick::-webkit-scrollbar-thumb { background: #dddefa; border-radius: 4px; }
  .dai-quick .btn {
    flex: 0 0 auto; white-space: nowrap;
    background: rgba(255,255,255,.9); border: 1px solid #e4e4fb; color: #4d4d9e;
    border-radius: 999px; padding: 4px 9px; font-size: 12px;
    box-shadow: 0 1px 2px rgba(90,90,190,.06);
    transition: all .15s ease;
  }
  .dai-quick .btn:hover {
    border-color: #b6b9f8; color: #5b5bd6; background: #f4f4ff;
    box-shadow: 0 2px 8px rgba(120,126,255,.14);
    transform: translateY(-1px);
  }
  .dai-quick .btn .fa, .dai-quick .btn .fas, .dai-quick .btn .far { color: #8b8ff5; margin-right: 5px; }
  shiny-chat-container {
    /* 0.5 \u8D77\u804A\u5929\u6839\u662F\u81EA\u5B9A\u4E49\u5143\u7D20 <shiny-chat-container>\uFF08\u65E7 class \u9009\u62E9\u5668\u5DF2\u5931\u914D\uFF09\uFF1B
       height:auto \u5185\u8054\u6837\u5F0F\u5FC5\u987B !important \u8986\u5199\uFF0C\u624D\u80FD\u6491\u6EE1\u5916\u5C42\u5305\u76D2 */
    height: 100% !important;
    background: rgba(255,255,255,.8);
    border: 1px solid #eceafb; border-radius: 18px; overflow: hidden;
    box-shadow: 0 8px 28px rgba(80,84,180,.07);
  }
  .shiny-chat-layout { height: 100%; }
  .shiny-chat-messages-wrapper { height: 100%; flex: 1; }
  /* 0.5 \u7A7A\u4F1A\u8BDD\u628A greeting \u7528 margin:auto \u7EB5\u5411\u5C45\u4E2D\uFF08\u89C2\u611F\u5373\u300C\u4E2D\u95F4\u7A7A\u4E00\u5927\u5757\u300D\uFF09\uFF1A
     \u9876\u90E8\u951A\u5B9A\uFF0C\u56DE\u5230 0.2 \u65F6\u4EE3\u7684\u7D27\u51D1\u89C2\u611F */
  .shiny-chat-greeting { margin-block: 0 4px !important; color: #8f8fb8; }
  .shiny-chat-message.shiny-chat-user-message {
    background: linear-gradient(120deg,#e2e4ff,#d7f2fd);
    border: 1px solid #d5d8fa; color: #3f3a9e; border-radius: 16px 16px 4px 16px;
    box-shadow: 0 3px 10px rgba(102,110,240,.1);
  }
  .shiny-chat-message.shiny-chat-user-message .shiny-chat-message-content { color: #3f3a9e; }
  .shiny-chat-message.shiny-chat-user-message pre,
  .shiny-chat-message.shiny-chat-user-message code { color: #4c48b5; background: #ffffffcc; }
  .shiny-chat-messages .shiny-chat-message:not(.shiny-chat-user-message) .shiny-chat-message-content {
    background: #fff; border: 1px solid #f0eefc; border-radius: 14px;
    box-shadow: 0 2px 8px rgba(90,94,190,.05); color: #\u46466b;
  }
  .shiny-chat-input {
    background: rgba(255,255,255,.92); border: 1.5px solid #e5e5fb; border-radius: 14px;
    box-shadow: inset 0 1px 3px rgba(90,94,190,.05);
  }
  .shiny-chat-input:focus {
    border-color: #b3b8f9; box-shadow: 0 0 0 3px rgba(129,140,248,.15);
  }
  /* \u8F93\u5165\u6846\u591A\u884C\u540E\u81EA\u8EAB\u6EDA\u52A8\u6761\u4F1A\u538B\u5728\u53D1\u9001\u6309\u94AE\u4E0B\u9762\uFF1A\u6574\u4E2A\u85CF\u6389\uFF08\u6EDA\u8F6E/\u952E\u76D8\u4ECD\u53EF\u6EDA\uFF09 */
  .shiny-chat-input textarea,
  .shiny-chat-input .ProseMirror { scrollbar-width: none; -ms-overflow-style: none; }
  .shiny-chat-input textarea::-webkit-scrollbar,
  .shiny-chat-input .ProseMirror::-webkit-scrollbar { width: 0; height: 0; display: none; }
  .shiny-chat-btn-send {
    background: linear-gradient(120deg,#9aa0fa,#7fd8f2); border: 0;
    border-radius: 12px; color: #fff !important;
  }
  .shiny-chat-btn-send:hover { filter: brightness(1.06); }
  .shiny-chat-footer { color: #b7b9e2; }
  .modal-content { border-radius: 16px; overflow: hidden;
    box-shadow: 0 20px 60px rgba(70,74,160,.18); }
  .modal-header {
    background: linear-gradient(120deg,#f0eefe,#e8f7fd); color: #\u5050b4; border: 0;
  }
  .modal-header .modal-title { font-weight: 700; }
  .modal-header .close, .modal-header button.close { color: #7b7bc8; text-shadow: none; opacity: .9; }
  .modal-body { padding: 16px 18px 6px; background: #fdfcff; }
  .modal-footer { border: 0; background: #fdfcff; padding: 10px 18px 16px; }
  .dai-section {
    background: #fff; border: 1px solid #eff0fd; border-radius: 14px;
    padding: 12px 14px 4px; margin-bottom: 12px;
    box-shadow: 0 1px 4px rgba(90,94,190,.05);
  }
  .dai-section h6 {
    color: #\u7476d8; font-weight: 700; margin: 0 0 10px 0;
    font-size: 13px; letter-spacing: .5px;
    display: flex; align-items: center; gap: 6px;
  }
  .dai-section h6 .fa { color: #9a9ef8; }
  .form-control:focus, .selectize-input.focus {
    border-color: #b3b8f9; box-shadow: 0 0 0 3px rgba(129,140,248,.12);
  }
  .dai-btn-primary {
    background: linear-gradient(120deg,#898cf8,#57cfe8) !important;
    color: #fff !important; border: 0 !important; border-radius: 10px;
    box-shadow: 0 3px 10px rgba(110,118,248,.25);
  }
  .dai-btn-primary:hover { filter: brightness(1.08); }
  .dai-page-wrap { max-width: 640px; margin: 14px auto; }
  .dai-page-card {
    background: rgba(255,255,255,.9); border: 1px solid #edecfc; border-radius: 18px;
    padding: 18px 20px; box-shadow: 0 10px 34px rgba(96,100,180,.08);
  }
  ",
  # \u5386\u53F2\u62BD\u5C49\u6309\u94AE\uFF08show_history=TRUE\uFF09\u56DE\u5F52\u65F6\uFF0C\u6D88\u606F\u9876\u90E8\u91CD\u65B0\u7559\u51FA\u6309\u94AE\u9AD8\u5EA6\uFF1B
  # \u5173\u95ED\u65F6\u56DE\u5230 0.3 \u7684\u7D27\u51D1 padding
  if (isTRUE(history))
    "
  .shiny-chat-messages { padding-top: 34px !important; }
  " else "
  .shiny-chat-messages { padding-top: 4px !important; }
  ",
  # \u9762\u677F\u9875\u4E13\u7528\uFF1A\u6574\u9875 flex \u5E03\u5C40\uFF0C\u804A\u5929\u533A\u5438\u6536\u5269\u4F59\u9AD8\u5EA6\uFF0C\u6839\u6EDA\u52A8\u6761\u6C38\u4E45\u9000\u573A
  # \uFF08\u6B64\u524D calc(100vh-150px) \u5728\u5934\u90E8\u6362\u884C/\u7D27\u51D1\u89C6\u53E3\u4E0B\u4F1A\u6EA2\u51FA\u5341\u51E0\u50CF\u7D20\uFF0C\u51FA\u73B0\u9875\u9762\u7EA7\u4E0B\u62C9\u6761\uFF09\u3002
  # \u8BBE\u7F6E\u72EC\u7ACB\u9875\u5171\u7528\u672C CSS\uFF0C\u4F46\u8D70 panel=FALSE\uFF0C\u4FDD\u6301\u53EF\u6EDA\u52A8\u3002
  if (isTRUE(panel))
    "
  html, body { height: 100%; }
  body { overflow: hidden; }
  .dai-wrap { display: flex; flex-direction: column; height: 100vh; }
  .dai-head, .dai-quick, .dai-foot { flex: 0 0 auto; }
  .dai-chat-holder {
    flex: 1 1 auto; min-height: 0;
    display: flex; flex-direction: column;
  }
  .dai-chat-holder shiny-chat-container {
    flex: 1 1 auto !important; min-height: 0 !important; height: auto !important;
  }
  /* 0.6 \u62BD\u5C49\u641C\u7D22\u6846\u4FEE\u5B57\u53E0\uFF1Ashinychat \u7528 padding-inline-start \u7ED9\u5DE6\u4FA7\u7EDD\u5BF9\u5B9A\u4F4D\u56FE\u6807
     \u7559\u4F4D\uFF0C\u672C\u9875 Bootstrap .form-control \u7684 padding \u7B80\u5199\u6309\u6CE8\u5165\u987A\u5E8F\u53EF\u80FD\u628A\u5B83\u76D6\u6389
     \uFF08\u56FE\u6807\u538B\u5728 Search\u2026 \u5360\u4F4D\u6587\u5B57\u4E0A\uFF0C0.6 \u5B9E\u6D4B\uFF09\u3002\u7528\u66F4\u9AD8\u4F18\u5148\u7EA7\u9009\u62E9\u5668\u9489\u6B7B\uFF0C
     \u5E76\u7ED9\u4E0D\u652F\u6301
     \u903B\u8F91\u5C5E\u6027\u7684\u65E7\u5185\u6838\u8865\u7269\u7406 left\u3002 */
  .shiny-chat-history-search-wrap .shiny-chat-history-search {
    padding-left: 1.75rem; padding-right: .75rem;
  }
  .shiny-chat-history-search-wrap .shiny-chat-history-search-icon {
    left: .5rem;
  }
  " else ""
  )
}

# \u5305 Logo\uff08\u5934\u90E8\u6807\u9898\u53F3\u4FA7\uFF09\uff1alogo.png \u7ECF data URI \u5185\u8054\uFF08\u590D\u7528 .dai_image_data_uri\uFF09\u3002
# URI \u7F13\u5B58\uFF0C\u6BCF\u8FDB\u7A0B\u53EA\u7F16\u4E00\u6B21\uFF1B\u627E\u4E0D\u5230\u6587\u4EF6\u65F6\u8FD4\u56DE\u7A7A\u5B57\u7B26\u4E32\uFF0C\u4E0D\u5F71\u54CD\u9762\u677F\u5176\u5B83\u529F\u80FD\u3002
# \u8DE8\u7248\u5751\uFF1aR \u5B89\u88C5\u6811\u4E0D\u542B man/\uFF0C\u5355\u8D70 man/figures \u5728\u88C5\u597D\u7684\u5305\u91CC\u662F\u7A7A\u2014\u2014
# \u8D44\u6E90\u53CC\u5907\uFF1aman/figures\uFF08\u6E90\u7801\u4F4D\uFF0Cload_all \u53EF\u89C1\uFF09+ inst/figures\uFF08\u5B89\u88C5\u4F4D\uFF0C\u786C\u62F7\u8D1D\uFF09\uFF0C\u4E24\u8DEF\u90FD\u8BD5\u3002
.dai_logo_env <- new.env(parent = emptyenv())

.dai_logo_uri <- function() {
  if (!is.null(.dai_logo_env$uri)) return(.dai_logo_env$uri)
  .dai_logo_env$uri <- ""
  candidates <- c(
    system.file(file.path("man", "figures", "logo.png"), package = "daiRH"),
    system.file(file.path("figures", "logo.png"), package = "daiRH")
  )
  for (path in candidates) {
    if (nzchar(path) && file.exists(path)) {
      uri <- tryCatch(.dai_image_data_uri(path), error = function(e) "")
      if (nzchar(uri)) {
        .dai_logo_env$uri <- uri
        break
      }
    }
  }
  .dai_logo_env$uri
}

# \u6807\u9898\u53F3\u4FA7\u7684\u5305 Logo\uFF08img + data URI\uFF09\uFF1A\u81EA\u5BB6\u6807\u8BB0\u4E0D\u7ECF shinychat \u7684 markdown
# \u51C0\u5316\uFF08\u5B9E\u6D4B\u5B83\u4F1A\u5265\u6389 data: \u534F\u8BAE\u7684 src\uFF09\uFF0C\u6240\u4EE5\u56FA\u5B9A\u653E\u5728\u5934\u90E8\u3002
.dai_title_logo <- function(px = 28) {
  uri <- .dai_logo_uri()
  if (!nzchar(uri)) return(NULL)
  shiny::tags$img(
    src = uri, alt = "daiRH", class = "dai-title-logo",
    style = sprintf("height:%dpx;width:auto;border-radius:7px;box-shadow:0 2px 6px rgba(80,84,180,.16);", px)
  )
}

# \u5934\u9876\u5C0F\u673A\u5668\u4EBA\u5409\u7965\u7269\uFF08\u5185\u8054\u7EAF ASCII\uFF0C\u56E0\u5B58\u5728 HTML \u5B57\u7B26\u4E32\u4E2D\uFF09
.dai_mascot_svg <- function() {
  shiny::HTML(paste(
    '<svg class="dai-mascot" viewBox="0 0 64 64" width="26" height="26" aria-hidden="true">',
    '<defs><linearGradient id="daimg" x1="0" y1="0" x2="1" y2="1">',
    '<stop offset="0" stop-color="#8f92f7"/><stop offset="1" stop-color="#63d3f2"/>',
    '</linearGradient></defs>',
    '<path d="M14 24 L8 9 L24 15 Z" fill="url(#daimg)"/>',
    '<path d="M50 24 L56 9 L40 15 Z" fill="url(#daimg)"/>',
    '<line x1="32" y1="10" x2="32" y2="16" stroke="#9aa1f8" stroke-width="2.5" stroke-linecap="round"/>',
    '<circle cx="32" cy="8.6" r="2.4" fill="#f8a7d8"/>',
    '<circle cx="32" cy="36" r="21" fill="url(#daimg)"/>',
    '<circle cx="25" cy="36" r="3.4" fill="#fff"/>',
    '<circle cx="39" cy="36" r="3.4" fill="#fff"/>',
    '<circle cx="25.9" cy="36.5" r="1.7" fill="#3c3a72"/>',
    '<circle cx="39.9" cy="36.5" r="1.7" fill="#3c3a72"/>',
    '<ellipse cx="19.5" cy="42" rx="3" ry="1.9" fill="#f9a8cf" opacity="0.75"/>',
    '<ellipse cx="44.5" cy="42" rx="3" ry="1.9" fill="#f9a8cf" opacity="0.75"/>',
    '<path d="M28 44 q4 3.4 8 0" stroke="#5b57a8" stroke-width="2" fill="none" stroke-linecap="round"/>',
    '</svg>',
    sep = " "
  ))
}

# 0.8 \u9762\u677F\u5DE6\u4FA7\u5409\u7965\u7269\u53EF\u6362\uFF1Acfg$mascot \u586B\u672C\u5730\u8DEF\u5F84\u6216 http(s) URL\uFF08\u7559\u7A7A = \u5185\u7F6E\u5C0F\u673A\u5668\u4EBA\uFF09\u3002
# \u56FE\u7ECF data URI \u5185\u8054\uFF08\u4E0E bg_image \u540C\u673A\u5236\uFF09\uFF1B\u7528\u7B2C\u4E09\u65B9\u63D2\u753B\u65F6\u8BF7\u4FDD\u7559\u4F5C\u8005\u7F72\u540D\u3002
.dai_mascot <- function(cfg) {
  src <- trimws(as.character(cfg$mascot %||% ""))
  if (nzchar(src)) {
    uri <- NULL
    if (grepl("^https?://", src, ignore.case = TRUE)) {
      uri <- src
    } else if (file.exists(src)) {
      uri <- tryCatch(.dai_image_data_uri(src), error = function(e) NULL)
    }
    if (!is.null(uri)) {
      return(shiny::tags$img(
        src = uri, alt = "daiRH", class = "dai-mascot",
        style = "height:26px;width:auto;border-radius:6px;"
      ))
    }
  }
  .dai_mascot_svg()
}

# \u80CC\u666F\u56FE\u5C42\uFF1Acfg$bg_image \u53EF\u586B\u672C\u5730\u8DEF\u5F84\u6216 http(s) URL\uFF1B
# \u7559\u7A7A\u65F6\u7528\u5185\u7F6E\u6DE1\u5F69\u591C\u6A31\u00A0SVG\uFF08inst/static\uFF09\u3002\u56FE\u7247\u7ECF data URI \u5185\u8054\uFF0C
# \u907F\u514D\u6D4F\u89C8\u5668\u4ECE http \u9875\u5F15\u7528\u672C\u5730 file:// \u88AB\u62E6\u622A\u3002
.dai_bg_layer <- function(cfg) {
  src <- trimws(as.character(cfg$bg_image %||% ""))
  url <- NULL
  if (nzchar(src)) {
    if (grepl("^https?://", src, ignore.case = TRUE)) {
      url <- src
    } else if (file.exists(src)) {
      url <- tryCatch(.dai_image_data_uri(src), error = function(e) NULL)
    }
  }
  if (is.null(url)) {
    asset <- system.file("static", "panel-default-bg.svg", package = "daiRH")
    if (nzchar(asset) && file.exists(asset)) {
      url <- tryCatch(.dai_image_data_uri(asset), error = function(e) NULL)
    }
  }
  style_body <- if (is.null(url)) "display:none;" else sprintf(
    "background-image:url('%s');", url
  )
  shiny::div(class = "dai-bg-layer", style = style_body)
}

.dai_image_data_uri <- function(path, max_bytes = 8e6) {
  ext <- tolower(tools::file_ext(path))
  kind <- switch(ext,
    svg = "image/svg+xml", png = "image/png", jpeg = "image/jpeg",
    jpg = "image/jpeg", webp = "image/webp", gif = "image/gif",
    bmp = "image/bmp", NULL
  )
  if (is.null(kind)) {
    stop("\u4E0D\u652F\u6301\u7684\u80CC\u666F\u56FE\u683C\u5F0F\uFF1A.", ext, call. = FALSE)
  }
  size <- file.info(path)$size
  if (!is.finite(size) || size <= 0 || size > max_bytes) {
    stop("\u80CC\u666F\u56FE\u7247\u6587\u4EF6\u8FC7\u5927\u6216\u4E0D\u53EF\u8BFB\uFF08\u4E0A\u9650 8MB\uFF09", call. = FALSE)
  }
  b64 <- base64enc::base64encode(readBin(path, what = "raw", n = size))
  paste0("data:", kind, ";base64,", b64)
}

#' \u6784\u5EFA\u9762\u677F UI
#'
#' @param cfg \u914D\u7F6E\u5217\u8868\uFF08\u53EF\u9009\uFF0C\u63D0\u4F9B\u540E\u4F7F\u7528\u5176 bg_image \u4F5C\u4E3A\u80CC\u666F\uFF09
dairh_panel_ui <- function(cfg = NULL) {
  hist <- .dairh_history_enabled(cfg)
  css <- .dai_panel_css(history = hist, panel = TRUE)
  shiny::fluidPage(
    shiny::tags$style(shiny::HTML(css)),
    shinyjs::useShinyjs(),
    .dai_bg_layer(cfg),
    shiny::div(
      class = "dai-wrap",
      shiny::div(
        class = "dai-head",
        shiny::span(class = "dai-title", .dai_mascot(cfg), "DaiRH \u52A9\u624B", .dai_title_logo()),
        shiny::uiOutput("client_info", inline = TRUE),
        shinyjs::hidden(shiny::div(style = "flex:1", class = "flex-spacer")),
        # 0.7 \u6A21\u5F0F\u70ED\u5207\u6362\uFF08plan/build\uFF09\uFF1Alabel \u968F\u72B6\u6001\u53D8\uFF1B\u70B9\u51FB\u7ECF .dairh_set_mode \u539F\u5730\u6362
        # \u63D0\u793A\u8BCD\u4E0E\u5DE5\u5177\u96C6\uFF0C\u5BF9\u8BDD\u4E0E\u786C\u9884\u7B97\u8BA1\u6570\u4E0D\u4E22\u3002
        shiny::actionButton("btn_mode",
          label = if (identical(.dairh_norm_mode(cfg$mode %||% "build"), "plan")) "\u8BA1\u5212" else "\u6784\u5EFA",
          icon = shiny::icon(if (identical(.dairh_norm_mode(cfg$mode %||% "build"), "plan")) "clipboard-list" else "hammer"),
          class = "dai-mode-btn",
          title = "\u6A21\u5F0F\u70ED\u5207\u6362\uFF08\u5F53\u573A\u751F\u6548\uFF0C\u5BF9\u8BDD\u4E0D\u4E22\uFF09\uFF1A\u8BA1\u5212 = \u53EA\u8BFB\u8C03\u7814\u3001\u4EA4\u4ED8\u7ED3\u6784\u5316\u8BA1\u5212\uFF1B\u6784\u5EFA = \u5168\u5DE5\u5177"
        ),
        shiny::actionLink("btn_clear", "", shiny::icon("eraser"),
          title = "\u6E05\u7A7A\u5BF9\u8BDD\uFF08\u65B0\u4F1A\u8BDD\uFF1A\u6E05\u804A\u8BB0\u4E0E\u786C\u9884\u7B97\u91CD\u7F6E\uFF0C\u4E0D\u91CD\u542F\u5B50\u8FDB\u7A0B\uFF09"),
        shiny::actionLink("btn_settings", "", shiny::icon("gear"), title = "\u8BBE\u7F6E")
      ),
      shiny::div(
        class = "dai-quick",
        shiny::actionButton("btn_explain", "\u89E3\u91CA\u5F53\u524D\u6587\u4EF6", shiny::icon("file-code")),
        shiny::actionButton("btn_explain_sel", "\u8BB2\u89E3\u9009\u4E2D\u4EE3\u7801", shiny::icon("scissors")),
        shiny::actionButton("btn_review", "\u5BA1\u67E5\u5F53\u524D\u6587\u4EF6", shiny::icon("search")),
        shiny::actionButton("btn_docs", "R \u6587\u6863\u95EE\u7B54", shiny::icon("book"))
      ),
      shiny::div(
        class = "dai-chat-holder",
        shinychat::chat_ui(
          "chat",
          placeholder = "\u7ED9 DaiRH \u53D1\u4EFB\u52A1\uFF0C\u6216\u70B9\u4E0A\u65B9\u5FEB\u6377\u6309\u94AE...",
          show_thinking_after_s = if (isTRUE(cfg$show_thinking)) 0 else -1,
          show_history = hist
        )
      ),
      # 0.6 \u5E95\u90E8\u72B6\u6001\u680F\uFF1Atoken \u8BA1\u91CF + \u538B\u7F29\u6309\u94AE\uFF08provider\u00B7\u6A21\u578B\u00B7\u5DE5\u5177\u6570\u7559\u5728\u6807\u9898\u680F\uFF1B
      # \u4E24\u8005\u90FD\u585E\u4E00\u4FA7\u90FD\u6324\u2014\u2014\u5934\u90E8\u653E\u8EAB\u4EFD\u3001\u5E95\u90E8\u653E\u8BA1\u91CF\uFF0C0.6 \u5B9E\u6D4B\u5B9A\u7A3F\uFF09\u3002
      shiny::div(
        class = "dai-foot",
        # 0.7 \u5E95\u90E8\u72B6\u6001\u680F\uFF1A\u5DE5\u4F5C\u65F6\u957F\uFF08\u5DE5\u4F5C\u4E2D\u6D3B\u8DF3/\u672C\u8F6E\u51BB\u7ED3\uFF09+ token \u8BA1\u91CF + \u601D\u8003\u5F3A\u5EA6 + \u538B\u7F29
        shiny::uiOutput("work_info", inline = TRUE),
        shiny::uiOutput("token_info", inline = TRUE),
        shinyjs::hidden(shiny::div(style = "flex:1", class = "flex-spacer")),
        shiny::actionLink("btn_effort",
          paste0("\u601D\u8003:", if (!nzchar(.dairh_norm_effort(cfg$reasoning_effort %||% ""))) "\u5173" else
            c(low = "\u4F4E", medium = "\u4E2D", high = "\u9AD8")[[.dairh_norm_effort(cfg$reasoning_effort %||% "")]]),
          shiny::icon("brain"),
          title = "\u601D\u8003\u5F3A\u5EA6 reasoning_effort\uFF08\u900F\u4F20\u7ED9\u7F51\u5173\uFF0C\u5FAA\u73AF \u5173\u2192\u4F4E\u2192\u4E2D\u2192\u9AD8\uFF09\uFF1B\u5199\u5165\u914D\u7F6E\uFF0C\u91CD\u5F00\u9762\u677F\u540E\u751F\u6548"),
        shiny::actionLink("btn_compact", "\u538B\u7F29\u4E0A\u4E0B\u6587", shiny::icon("compress"),
          title = "\u538B\u7F29\u4E0A\u4E0B\u6587\uFF08\u6A21\u578B\u603B\u7ED3\u5F53\u524D\u5BF9\u8BDD\u5E76\u91CD\u6C34\u5408\uFF1B\u539F\u5BF9\u8BDD\u5B58\u5165\u5386\u53F2\u62BD\u5C49\uFF09")
      )
    )
  )
}

# \u9762\u677F\u670D\u52A1\u7AEF\uFF1A\u63A5\u5165 agent \u5BA2\u6237\u7AEF + \u5FEB\u6377\u4EFB\u52A1 + \u8BBE\u7F6E\u5F39\u7A97
# \u521D\u59CB\u5316\uFF08\u6784\u5EFA\u5BA2\u6237\u7AEF\uFF09\u5931\u8D25\u65F6\u4E0D\u80FD\u6B7B\u58F3\uFF1A\u4ECD\u8981\u6E32\u67D3 pill \u4E0E\u62A5\u9519\u5361\uFF0C
# \u5426\u5219\u7528\u6237\u53EA\u770B\u5230\u7A7A\u58F3\u9762\u677F\u627E\u4E0D\u5230\u4EFB\u4F55\u7EBF\u7D22\uFF08Provider \u5199\u574F\u65F6\u66FE\u5C31\u662F\u8FD9\u6837\uFF09\u3002
.dairh_panel_server_impl <- function(cfg) {
  function(input, output, session) {
    init_err <- NULL
    client <- tryCatch(
      dairh_new_agent(cfg),
      error = function(e) {
        init_err <<- conditionMessage(e)
        NULL
      }
    )

    n_tools <- tryCatch(length(dairh_agent_tools(cfg)), error = function(e) NA_integer_)
    # 0.7\uFF1A\u8BA1\u5212\u6A21\u5F0F\u7684\u5DE5\u5177\u6570\u3002rv_mode \u63D0\u524D\u5230 client_info \u4E4B\u524D\u5B9A\u4E49\u2014\u2014\u6807\u9898\u680F pill
    # \u968F\u6A21\u5F0F\u5B9E\u65F6\u53D8\u5316\uFF08\u5DE5\u5177\u6570 plan=\u88C1\u526A\u540E\uFF0Cbuild=\u5168\u91CF\uFF09\uFF0C\u6D88\u8D39 rv_mode \u5EFA\u7ACB\u8BA2\u9605\u3002
    cfg_plan <- cfg
    cfg_plan$mode <- "plan"
    n_tools_plan <- tryCatch(length(dairh_agent_tools(cfg_plan)),
      error = function(e) NA_integer_)
    rv_mode <- shiny::reactiveVal(.dairh_norm_mode(cfg$mode %||% "build"))
    output$client_info <- shiny::renderText({
      if (!is.null(init_err)) {
        sprintf(
          "<span class='dai-sub' style='color:#ffd8a8'>\u26A0 %s</span>",
          htmltools::htmlEscape(.dai_clip(init_err, 100))
        )
      } else {
        m <- rv_mode()
        n_eff <- if (identical(m, "plan") && !is.na(n_tools_plan)) n_tools_plan else n_tools
        tools_txt <- if (is.na(n_eff)) "" else sprintf(" \u00B7 %d \u5DE5\u5177", n_eff)
        sprintf("<span class='dai-sub'>%s \u00B7 %s%s</span>", cfg$provider, cfg$model, tools_txt)
      }
    })

    # 0.8 \u72B6\u6001\u680F\u5237\u65B0\u6273\u673A\uFF1Aset_turns\uFF08\u538B\u7F29/\u6E05\u7A7A\u66FF\u6362 turns\uFF09\u5BF9 shinychat \u4E0D\u53EF\u89C1\uFF0C
    # last_turn \u4E0D\u5931\u6548 \u2192 \u72B6\u6001\u680F\u4F1A\u4E00\u76F4\u663E\u793A\u65E7\u8D26\u3002\u663E\u5F0F\u8BA1\u6570\u6273\u624B\uFF0C\u538B\u7F29/\u6E05\u7A7A\u540E bump\u3002
    rv_tok <- shiny::reactiveVal(0L)
    # 0.8 \u65E7\u8D26\u7ED3\u8F6C\uFF1Aturns \u88AB\u6458\u8981/\u6E05\u7A7A\u66FF\u6362\u540E get_tokens \u5F52\u96F6\uFF0C\u4F46\u82B1\u8D39\u662F\u771F\u5B9E
    # \u53D1\u751F\u7684\u2014\u2014\u538B\u7F29\u524D\u628A\u7D2F\u8BA1\u7ED3\u8F6C\u8FDB rv_carry\uFF0C\u72B6\u6001\u680F = get_tokens + carry\u3002
    rv_carry <- shiny::reactiveVal(c(0, 0))
    # 0.8 \u538B\u7F29/\u6E05\u7A7A\u540E\u7684\u4E0A\u4E0B\u6587\u5360\u7528\u4F30\u7B97\uFF08\u65E0\u8BF7\u6C42\u4F9D\u636E\u65F6\u7684\u5360\u4F4D\u8BFB\u6570\uFF0C\u6807"\u4F30\u7B97"\uFF09
    rv_est <- shiny::reactiveVal(0)
    # 0.9 \u538B\u7F29\u89E6\u53D1\u63D0\u793A\uFF1A\u9608\u503C\u63D0\u793A\u53EA\u63A8\u4E00\u6B21\uFF0C\u538B\u7F29/\u6E05\u7A7A\u540E\u964D\u56DE\u9608\u503C\u4EE5\u4E0B\u81EA\u52A8\u91CD\u65B0\u6B66\u88C5\u3002
    hint_env <- new.env(parent = emptyenv())
    hint_env$fired <- FALSE

    # 0.6 \u6807\u9898\u680F\u8BA1\u91CF\uFF1A\u7D2F\u8BA1 token\uFF08\u8F93\u5165/\u8F93\u51FA\uFF09+ \u4E0A\u4E0B\u6587\u5BB9\u91CF\u3002\u5FC5\u987B\u663E\u5F0F\u6D88\u8D39
    # chat_mod$last_turn \u54CD\u5E94\u5F0F\u5EFA\u7ACB\u8BA2\u9605\u2014\u2014renderText \u91CC\u5168\u662F\u666E\u901A\u53D8\u91CF\u7684\u8BDD\u53EA\u5728
    # \u9996\u6B21 flush \u7B97\u4E00\u6B21\u3001\u6C38\u8FDC\u4E0D\u5237\u65B0\uFF080.6 \u5B9E\u6D4B\u8E29\u8FC7\uFF1A\u8F93\u5165\u8F93\u51FA\u4E0D\u663E\u793A\uFF09\u3002
    output$token_info <- shiny::renderText({
      if (is.null(client) || is.null(chat_mod)) return("")
      force(rv_tok()) # \u538B\u7F29/\u6E05\u7A7A\u540E\u7684\u663E\u5F0F\u5237\u65B0\u6273\u673A
      lt <- tryCatch(chat_mod$last_turn(), error = function(e) NULL)
      tb <- tryCatch(client$get_tokens(), error = function(e) NULL)
      if (!is.data.frame(tb)) tb <- data.frame(input = numeric(0), output = numeric(0))
      carry <- rv_carry()
      tin <- sum(tb$input %||% 0, na.rm = TRUE) + (carry[[1]] %||% 0)
      tout <- sum(tb$output %||% 0, na.rm = TRUE) + (carry[[2]] %||% 0)
      if ((!is.finite(tin) || tin <= 0) && (!is.finite(tout) || tout <= 0)) return("")
      seg_cum <- sprintf(
        "<span class='dai-tok' title='\u672C\u4F1A\u8BDD\u7D2F\u8BA1 token\uFF08\u8F93\u5165/\u8F93\u51FA\uFF09'>&#9889; %s / %s</span>",
        .dai_fmt_tokens(tin), .dai_fmt_tokens(tout)
      )
      # \u4E0A\u4E0B\u6587\u5BB9\u91CF\uFF1A\u5360\u7528 = \u6700\u8FD1\u4E00\u6B21\u8BF7\u6C42\u7684\u5B8C\u6574 prompt\uFF08input + cache_read\u2014\u2014
      # \u7F13\u5B58\u547D\u4E2D\u7684\u90E8\u5206\u7167\u6837\u5360\u7A97\u53E3\uFF1B0.8 \u4FEE\uFF1A\u7F13\u5B58\u8BA1\u8D39\u7F51\u5173\u7684 input \u53EA\u662F\u672A\u547D\u4E2D
      # \u589E\u91CF\uFF0C\u53EA\u8BFB\u5B83\u4F1A\u628A 123k \u5360\u7528\u663E\u793A\u6210 481/0.0%\uFF09\uFF1B\u5206\u6BCD = cfg$context_window
      # \uFF08\u7F51\u5173\u4E0D\u544A\u77E5\uFF0C\u8BBE\u7F6E\u91CC\u586B\uFF09\u3002\u7A97\u53E3\u672A\u77E5\u65F6\u53EA\u663E\u793A\u5360\u7528\uFF1B\u6700\u8FD1\u8BF7\u6C42\u7F3A tokens \u65F6
      # \u9000\u56DE get_tokens \u672B\u884C\u3002
      used <- .dairh_ctx_used(
        tryCatch(as.numeric(lt@tokens), error = function(e) NULL), tb
      )
      used_est <- FALSE
      if (is.null(used)) {
        # \u538B\u7F29/\u6E05\u7A7A\u540E\u65E0\u8BF7\u6C42\u4F9D\u636E \u2192 \u7528\u5B57\u7B26\u6570\u7C97\u4F30\u5360\u4F4D\uFF0C\u6807"\u4F30\u7B97"
        est <- rv_est()
        if (length(est) == 1L && is.finite(est) && est > 0) {
          used <- est
          used_est <- TRUE
        }
      }
      cw <- suppressWarnings(as.numeric(cfg$context_window)[[1]])
      # 0.9 \u538B\u7F29\u89E6\u53D1\u63D0\u793A\uFF1A\u5360\u7528\u8FC7\u9608\u503C \u2192 \u8BFB\u6570\u53D8\u8B66\u793A\u8272 + \u63A8\u4E00\u6B21\u901A\u77E5\uFF08\u964D\u56DE\u9608\u503C\u4EE5\u4E0B\u81EA\u52A8\u91CD\u65B0\u6B66\u88C5\uFF09\u3002
      hot <- .dairh_ctx_hot(used, cw, cfg$compact_hint %||% 0.7)
      if (hot && !isTRUE(hint_env$fired) && is.finite(cw) && cw > 0) {
        hint_env$fired <- TRUE
        shiny::showNotification(
          sprintf(
            "\u4E0A\u4E0B\u6587\u5360\u7528\u5DF2\u8FBE %s\uFF08\u7EA6 %.0f%%\uFF09\uFF0C\u5EFA\u8BAE\u70B9\u51FB\u8F93\u5165\u6846\u65C1\u7684\u201C\u538B\u7F29\u4E0A\u4E0B\u6587\u201D\u3002",
            .dai_fmt_tokens(used), min(100, used / cw * 100)
          ),
          type = "warning", duration = 10
        )
      } else if (!hot && isTRUE(hint_env$fired)) {
        hint_env$fired <- FALSE
      }
      seg_ctx <- ""
      if (!is.null(used)) {
        est_mark <- if (used_est) "\uFF08\u4F30\u7B97\uFF0C\u4E0B\u6B21\u8BF7\u6C42\u6821\u51C6\uFF09" else "\uFF08\u5B8C\u6574 prompt\uFF0C\u542B\u7F13\u5B58\u547D\u4E2D\uFF09"
        if (is.finite(cw) && cw > 0) {
          seg_ctx <- sprintf(
            "<span class='dai-tok%s' title='\u5F53\u524D\u4E0A\u4E0B\u6587\u5360\u7528%s / \u6A21\u578B\u4E0A\u4E0B\u6587\u7A97\u53E3'>\u00B7 \u4E0A\u4E0B\u6587 %s / %s (%.1f%%)</span>",
            if (hot) " dai-ctx-hot" else "",
            est_mark,
            .dai_fmt_tokens(used), .dai_fmt_tokens(cw),
            min(100, used / cw * 100)
          )
        } else {
          seg_ctx <- sprintf(
            "<span class='dai-tok' title='\u5F53\u524D\u4E0A\u4E0B\u6587\u5360\u7528%s'>\u00B7 \u4E0A\u4E0B\u6587 %s</span>",
            est_mark,
            .dai_fmt_tokens(used)
          )
        }
      }
      # 0.7 tok/s\uFF1A\u8BFB\u6F0F\u6597 rate env\uFF1B\u4EC5\u5F53\u8BB0\u5F55\u7684 turn \u4E0E\u5F53\u524D last_turn \u662F\u540C\u4E00\u5BF9\u8C61\u624D
      # \u663E\u793A\u2014\u2014\u8D77\u6807\u9898\u8D70 client$clone()\uFF08\u56DE\u8C03\u6309\u5F15\u7528\u5171\u4EAB\uFF09\uFF0C\u7528\u5BF9\u8C61\u4E00\u81F4\u6027\u8FC7\u6EE4\uFF0C
      # \u6807\u9898\u8BF7\u6C42\u4E0D\u6C61\u67D3\u4E3B\u5BF9\u8BDD\u901F\u5EA6\u663E\u793A\uFF1B\u4E0D\u5339\u914D\u65F6\u6BB5\u7701\u7565\uFF0C\u4E0B\u4E00\u8F6E\u56DE\u590D\u81EA\u52A8\u6062\u590D\u3002
      seg_speed <- ""
      renv <- attr(client, ".dairh_rate")
      if (!is.null(renv) && !is.null(lt)) {
        last <- renv$last
        if (!is.null(last) && identical(last$turn, lt)) {
          r <- suppressWarnings(as.numeric(last$tok_per_s %||% NA)[[1]])
          if (length(r) == 1L && is.finite(r) && r > 0) {
            seg_speed <- sprintf(
              "<span class='dai-tok' title='\u6700\u8FD1\u4E00\u6B21\u6A21\u578B\u8BF7\u6C42\u7684\u8F93\u51FA\u901F\u5EA6\uFF08\u8F93\u51FA token/\u79D2\uFF09'>\u00B7 %s tok/s</span>",
              format(r, nsmall = 0)
            )
          }
        }
      }
      paste0(seg_cum, " ", seg_ctx, " ", seg_speed)
    })

    chat_mod <- NULL
    if (!is.null(client)) {
      chat_mod <- shinychat::chat_server(
        "chat",
        client,
        greeting = paste0(
          "**DaiRH \u5DF2\u5C31\u7EEA**\u3000",
          cfg$provider, " \u00B7 ", cfg$model,
          "\n\n\u76F4\u63A5\u8F93\u5165\u4EFB\u52A1\u5373\u53EF\uFF0CAgent \u53EF\u8BFB\u5199\u6587\u4EF6\u3001\u8FD0\u884C\u4EE3\u7801\u3001\u67E5\u6587\u6863\u3002",
          if (isTRUE(cfg$restrict_paths)) paste0("\n\n\u6587\u4EF6\u64CD\u4F5C\u8303\u56F4\uFF1A", dairh_base_dir()),
          .dairh_greeting_bridge_line()
        ),
        history = .dairh_history_options(cfg, client)
      )
      # \u6253\u5F00\u9762\u677F\u81EA\u52A8\u7EED\u63A5\u6700\u8FD1\u4F1A\u8BDD\uFF1Ashinychat \u7684\u6D4F\u89C8\u5668\u81EA\u52A8\u6062\u590D\u4F9D\u8D56 localStorage\uFF0C
      # \u800C\u9762\u677F\u6BCF\u6B21\u542F\u52A8\u7AEF\u53E3\u968F\u673A\uFF08origin \u6BCF\u6B21\u90FD\u662F\u65B0\u7684\uFF09\u8D70\u4E0D\u901A\uFF1B\u8FD9\u91CC\u626B store \u53D6
      # \u6700\u65B0\u4F1A\u8BDD id\uFF0C\u7ECF\u5B98\u65B9\u8F93\u5165\u901A\u9053 _history_select \u89E6\u53D1\u6062\u590D\u2014\u2014shinychat \u4F1A\u628A
      # \u5B58\u6863\u8F6E\u6B21\u91CD\u6C34\u5408\u8FDB\u6211\u4EEC\u7684 client\uFF08\u542B\u5DE5\u5177\u914D\u5BF9\uFF09\uFF0C\u5DF2\u81EA\u884C\u6062\u590D\u8FC7\u5219\u8DF3\u8FC7\u3002
      session$onFlushed(function() {
        tryCatch({
          cid <- shiny::isolate(chat_mod$history$conversation_id())
          if (!is.null(cid)) return()
          id <- .dairh_history_latest_id()
          if (is.null(id)) return()
          session$setInputValue("chat_history_select",
            list(id = id, ts = as.numeric(Sys.time()) * 1000),
            priority = "event")
        }, error = function(e) NULL)
      }, once = TRUE)
    } else {
      shiny::showNotification(
        paste0("\u9762\u677F\u521D\u59CB\u5316\u5931\u8D25\uFF1A", init_err),
        type = "error", duration = NULL
      )
      shinychat::chat_append(
        "chat",
        paste0(
          "**DaiRH \u521D\u59CB\u5316\u5931\u8D25**\n\n",
          "```\n", init_err, "\n```\n\n",
          "\u70B9\u53F3\u4E0A\u9F7F\u8F6E\u6253\u5F00\u8BBE\u7F6E\uFF0C\u68C0\u67E5 Provider / base_url / API Key\uFF1B",
          "\u4FDD\u5B58\u540E\u91CD\u65B0\u6253\u5F00\u9762\u677F\u5373\u53EF\u3002"
        )
      )
    }

    # \u5FEB\u6377\u6309\u94AE \u2192 \u804A\u5929\u6846\uFF1A\u7ECF\u89E6\u53D1\u5668\u4E2D\u8F6C\u3002shinychat 0.5 \u7684 chat_server \u8DD1\u5728
    # \u8C03\u7528\u65B9\u4F5C\u7528\u57DF\uFF08\u4E0D\u518D\u6709 module \u547D\u540D\u7A7A\u95F4\uFF09\uFF0Cupdate_chat_user_input /
    # chat_clear / chat_append \u5728\u4E3B\u4F1A\u8BDD\u4F5C\u7528\u57DF\u76F4\u63A5\u8C03\u7528\u5373\u53EF\uFF0C\u65E0\u9700\u518D\u8F6C\u63A5\u3002
    chat_send <- shiny::reactiveValues(trigger = NULL)
    clear_rv <- shiny::reactiveValues(reset = 0L)
    shiny::observeEvent(chat_send$trigger, {
      shiny::req(chat_send$trigger)
      shinychat::update_chat_user_input(
        "chat", value = chat_send$trigger, submit = TRUE, focus = TRUE
      )
      chat_send$trigger <- NULL
    })
    # \u6E05\u7A7A\u5BF9\u8BDD\uFF08\u65B0\u4F1A\u8BDD\uFF09\u6267\u884C\u5668\uFF1A\u91CD\u7F6E Agent \u72B6\u6001 + \u6E05 UI + \u53D1\u95EE\u5019\u884C
    # \uFF08chat_clear / chat_append \u4F20\u4E3B\u4F1A\u8BDD session\uFF0C\u4E0E chat_server \u540C\u4F5C\u7528\u57DF\u4E00\u81F4\uFF09
    shiny::observeEvent(clear_rv$reset, {
      shiny::req(unname(clear_rv$reset) > 0L, !is.null(client))
      # \u5386\u53F2\u62BD\u5C49\u542F\u7528\u65F6\u5FC5\u987B\u8D70\u6A21\u5757\u7684 new_chat()\uFF1Achat_clear \u53EA\u6E05 UI \u4E0D\u52A8 store\uFF0C
      # \u4E0B\u6B21\u6062\u590D\u4F1A\u628A\u5DF2\u300C\u6E05\u7A7A\u300D\u7684\u4F1A\u8BDD\u53C8\u6367\u56DE\u6765\u3002\u5148\u5B58\u597D\u5F53\u524D\u4F1A\u8BDD\u518D\u5F00\u65B0\u7684\uFF0C
      # \u968F\u540E\u91CD\u7F6E Agent \u72B6\u6001\uFF08\u8BA1\u6570\u5668\u5F52\u96F6 + \u6E05\u6A21\u578B\u5386\u53F2\uFF09\u3002
      if (!is.null(chat_mod)) {
        tryCatch(chat_mod$new_chat(), error = function(e) NULL)
      } else {
        tryCatch(shinychat::chat_clear("chat", session = session),
          error = function(e) NULL)
      }
      tryCatch(.dai_reset_agent_state(client), error = function(e) NULL)
      tryCatch(shinychat::chat_append("chat", paste0(
        "**DaiRH \u65B0\u4F1A\u8BDD**\u3000", cfg$provider, " \u00B7 ", cfg$model,
        "\n\nAgent \u72B6\u6001\u5DF2\u91CD\u7F6E\uFF0C\u5355\u8F6E\u786C\u9884\u7B97\u5DF2\u5F52\u96F6\u3002"
      ), session = session), error = function(e) NULL)
    })
    # \u9009\u4E2D\u76F4\u53D1\u901A\u9053\u8F6E\u8BE2\uFF080.5 \u8D77 show_plot \u56FE\u7247\u76F4\u8FD4\u8FDB\u5BF9\u8BDD\uFF0C\u4E0D\u518D\u6709\u603B\u7EBF\u6D88\u8D39\uFF09\uFF1A
    # addin\uFF08\u4E3B\u4F1A\u8BDD\uFF09\u5199\u5165\u7684\u5F85\u53D1\u9001\u63D0\u793A\uFF0C\u8FD9\u91CC\u7EA6\u534A\u79D2\u5185\u6D88\u8D39\u3002
    # \u4E0D\u4F9D\u8D56\u4E3B\u4F1A\u8BDD later/\u63A7\u5236\u53F0\u6D3B\u52A8\u2014\u2014\u7A7A\u56DE\u8F66\u4E0D\u5237\u65B0\u5FEB\u7167\u4E5F\u4E0D\u5F71\u54CD\u8FD9\u6761\u8DEF\u3002
    shiny::observe({
      shiny::invalidateLater(400, session)
      pp <- tryCatch(.dairh_take_pending_prompt(), error = function(e) NULL)
      if (!is.null(pp)) {
        if (is.null(client)) {
          shiny::showNotification("\u9762\u677F\u5C1A\u672A\u5C31\u7EEA\uFF0C\u6536\u5230\u9009\u533A\u4F46\u65E0\u6CD5\u53D1\u9001\u3002", type = "error")
        } else {
          shinychat::update_chat_user_input("chat", value = pp,
            submit = TRUE, focus = TRUE)
        }
      }
    })
    .dairh_chat_send <- function(prompt) chat_send$trigger <- prompt

    # ---- 0.7 \u6A21\u5F0F\u70ED\u5207\u6362\uFF08plan/build\uFF09+ \u601D\u8003\u5F3A\u5EA6 + \u5DE5\u4F5C\u65F6\u957F --------------------
    # \u6A21\u5F0F\uFF1Arv_mode \u5DF2\u5728 client_info \u524D\u5B9A\u4E49\uFF08\u9762\u677F\u4F1A\u8BDD\u5185\u7684\u8FD0\u884C\u65F6\u72B6\u6001\uFF0C
    # \u70ED\u5207\u6362\u4E0D\u5199\u914D\u7F6E\u6587\u4EF6\u2014\u2014\u65B0\u4F1A\u8BDD\u9ED8\u8BA4\u503C\u5F52\u8BBE\u7F6E\u9875\u7BA1\uFF09\uFF0C\u8FD9\u91CC\u53EA\u6302\u89C2\u5BDF\u5668\u3002
    .dai_mode_view <- function(m) {
      if (identical(m, "plan")) {
        list(label = "\u8BA1\u5212", icon = "clipboard-list")
      } else {
        list(label = "\u6784\u5EFA", icon = "hammer")
      }
    }
    shiny::observeEvent(rv_mode(), {
      v <- .dai_mode_view(rv_mode())
      shiny::updateActionButton(session, "btn_mode",
        label = v$label, icon = shiny::icon(v$icon))
    })
    shiny::observeEvent(input$btn_mode, {
      if (is.null(client)) {
        shiny::showNotification("\u9762\u677F\u521D\u59CB\u5316\u5931\u8D25\uFF0C\u6CA1\u6709\u53EF\u5207\u6362\u6A21\u5F0F\u7684\u4F1A\u8BDD\u3002", type = "error")
        return()
      }
      new_mode <- if (identical(rv_mode(), "plan")) "build" else "plan"
      ok <- tryCatch({
        .dairh_set_mode(client, new_mode, cfg)
        TRUE
      }, error = function(e) {
        shiny::showNotification(paste0("\u6A21\u5F0F\u5207\u6362\u5931\u8D25\uFF1A", conditionMessage(e)), type = "error")
        FALSE
      })
      if (isTRUE(ok)) {
        rv_mode(new_mode)
        shiny::showNotification(
          if (identical(new_mode, "plan"))
            "\u5DF2\u5207\u6362\u5230\u8BA1\u5212\u6A21\u5F0F\uFF1A\u53EA\u8BFB\u8C03\u7814\uFF0C\u4EA4\u4ED8\u7ED3\u6784\u5316\u8BA1\u5212\uFF08\u5199/\u6267\u884C\u7C7B\u5DE5\u5177\u5DF2\u7269\u7406\u88C1\u526A\uFF09\u3002"
          else
            "\u5DF2\u5207\u6362\u5230\u6784\u5EFA\u6A21\u5F0F\uFF1A\u5168\u5DE5\u5177\u6062\u590D\u3002",
          type = "message", duration = 4
        )
      }
    })

    # \u601D\u8003\u5F3A\u5EA6\u5FAA\u73AF\u6309\u94AE\uFF1A\u5199\u914D\u7F6E\u6301\u4E45\u5316\uFF1Bellmer 0.5 \u7684 Chat \u65E0 params \u70ED\u6539\u53E3
    # \uFF08\u81EA\u7701\u786E\u8BA4\uFF1A\u65E0 set_params \u4E5F\u65E0 params \u6D3B\u52A8\u7ED1\u5B9A\uFF09\uFF0C\u8BED\u4E49\u4E3A"\u91CD\u5F00\u9762\u677F\u751F\u6548"\u3002
    .dai_effort_seq <- c("", "low", "medium", "high")
    .dai_effort_zh <- function(e) switch(e, low = "\u4F4E", medium = "\u4E2D", high = "\u9AD8", "\u5173")
    rv_effort <- shiny::reactiveVal(.dairh_norm_effort(cfg$reasoning_effort %||% ""))
    shiny::observeEvent(rv_effort(), {
      shiny::updateActionButton(session, "btn_effort",
        label = paste0("\u601D\u8003:", .dai_effort_zh(rv_effort())))
    })
    shiny::observeEvent(input$btn_effort, {
      idx <- which(.dai_effort_seq == rv_effort())
      if (!length(idx)) idx <- 1L
      nxt <- .dai_effort_seq[[idx %% length(.dai_effort_seq) + 1L]]
      rv_effort(nxt)
      tryCatch(dairh_config_set(reasoning_effort = nxt), error = function(e) NULL)
      shiny::showNotification(
        paste0("\u601D\u8003\u5F3A\u5EA6\uFF1A", .dai_effort_zh(nxt),
          if (!nzchar(nxt)) "\uFF08\u4E0D\u53D1\u9001\u8BE5\u5B57\u6BB5\uFF09" else "\uFF08\u5DF2\u5199\u5165\u914D\u7F6E\uFF1B\u91CD\u5F00\u9762\u677F\u540E\u751F\u6548\uFF09"),
        type = "message", duration = 4
      )
    })

    # \u5DE5\u4F5C\u65F6\u957F\uFF1Ashinychat \u7684 status \u5728 streaming\uFF08\u8986\u76D6\u6574\u4E2A\u5DE5\u5177\u5FAA\u73AF\uFF09/ idle \u95F4\u7FFB\u8F6C\u3002
    # observe \u8D1F\u8D23\u8BB0\u8D26\uFF08\u8BB0\u8D77\u70B9 / \u51BB\u7ED3\u4E0A\u8F6E\u8017\u65F6\uFF09\uFF1BrenderText \u4EC5 streaming \u65F6\u8BA2\u9605
    # 1s timer \u6D3B\u8DF3\uFF0Cidle \u663E\u793A\u4E0A\u8F6E"\u00B7 \u672C\u8F6E m\u5206s\u79D2"\uFF08\u4E0D\u8BA2\u9605 timer\uFF0C\u4E0D\u7A7A\u8F6C\uFF09\u3002
    work <- shiny::reactiveValues(start = NULL, last_secs = NA_real_)
    work_timer <- shiny::reactiveTimer(1000, session)
    shiny::observe({
      st <- tryCatch(chat_mod$status(), error = function(e) NULL)
      if (is.null(st)) return()
      if (identical(st, "streaming")) {
        if (is.null(work$start)) work$start <- Sys.time()
      } else if (!is.null(work$start)) {
        work$last_secs <- as.numeric(difftime(Sys.time(), work$start, units = "secs"))
        work$start <- NULL
      }
    })
    output$work_info <- shiny::renderText({
      if (is.null(chat_mod)) return("")
      st <- tryCatch(chat_mod$status(), error = function(e) NULL)
      if (identical(st, "streaming")) {
        work_timer()
        secs <- as.numeric(difftime(Sys.time(), work$start %||% Sys.time(), units = "secs"))
        sprintf("<span class='dai-tok' title='\u672C\u8F6E\u4EFB\u52A1\u5DF2\u8FDB\u884C\u65F6\u95F4'>&#9201; \u5DE5\u4F5C\u4E2D %s</span>",
          .dai_fmt_dur(secs))
      } else {
        ls <- work$last_secs
        if (length(ls) == 1L && is.finite(ls) && ls >= 1) {
          sprintf("<span class='dai-tok' title='\u4E0A\u4E00\u8F6E\u4EFB\u52A1\u603B\u8017\u65F6'>\u00B7 \u672C\u8F6E %s</span>",
            .dai_fmt_dur(ls))
        } else ""
      }
    })

    # \u6E05\u7A7A\u5BF9\u8BDD\uFF08\u65B0\u4F1A\u8BDD\uFF09\u6309\u94AE\uFF1A\u5F39\u7A97\u786E\u8BA4\u540E\u4EA4\u7ED9\u4E0A\u65B9\u6267\u884C\u5668
    shiny::observeEvent(input$btn_clear, {
      clear_txt <- if (!is.null(chat_mod))
        "\u5C06\u5F00\u542F\u65B0\u4F1A\u8BDD\u5E76\u91CD\u7F6E Agent \u72B6\u6001\uFF08\u542B\u5355\u8F6E\u786C\u9884\u7B97\u8BA1\u6570\uFF09\uFF1B\u5F53\u524D\u4F1A\u8BDD\u5B58\u5165\u5386\u53F2\u62BD\u5C49\uFF0C\u53EF\u968F\u65F6\u627E\u56DE\u3002"
      else
        "\u5C06\u6E05\u9664\u804A\u8BB0\u5E76\u91CD\u7F6E Agent \u4F1A\u8BDD\uFF08\u542B\u5355\u8F6E\u786C\u9884\u7B97\u8BA1\u6570\uFF09\u3002\u9762\u677F\u5B50\u8FDB\u7A0B\u4E0D\u91CD\u542F\uFF1B\u6B64\u64CD\u4F5C\u4E0D\u53EF\u64A4\u9500\u3002"
      shiny::showModal(shiny::modalDialog(
        title = shiny::tagList(shiny::icon("eraser"), "\u6E05\u7A7A\u5BF9\u8BDD\uFF1F"),
        shiny::p(clear_txt),
        footer = list(
          shiny::actionButton("dai_clear_ok", "\u786E\u8BA4\u6E05\u7A7A", class = "dai-btn-primary"),
          shiny::modalButton("\u53D6\u6D88")
        ),
        easyClose = TRUE
      ))
    })
    shiny::observeEvent(input$dai_clear_ok, {
      shiny::removeModal()
      if (is.null(client)) {
        shiny::showNotification(
          "\u9762\u677F\u521D\u59CB\u5316\u5931\u8D25\uFF0C\u6CA1\u6709\u53EF\u6E05\u7A7A\u7684\u4F1A\u8BDD\u3002", type = "error"
        )
        return()
      }
      clear_rv$reset <- clear_rv$reset + 1L
      # \u65B0\u4F1A\u8BDD\uFF1A\u5DE5\u4F5C\u65F6\u957F\u4ECE\u96F6\u8BA1
      work$start <- NULL
      work$last_secs <- NA_real_
      # 0.8 \u65B0\u4F1A\u8BDD\uFF1A\u7D2F\u8BA1\u7ED3\u8F6C\u6E05\u96F6 + \u72B6\u6001\u680F\u5F3A\u5236\u5237\u65B0
      rv_carry(c(0, 0))
      rv_est(0)
      rv_tok(rv_tok() + 1L)
    })

    # \u538B\u7F29\u4E0A\u4E0B\u6587\uFF080.6\uFF09\uFF1A\u786E\u8BA4\u5F39\u7A97 \u2192 \u6458\u8981\uFF08\u4E3B\u6A21\u578B\u4E00\u6B21\u6027\u65E0\u5DE5\u5177 Chat\uFF1B\u5FC5\u987B\u53D1\u751F\u5728
    # new_chat() \u5B58\u6863\u4E4B\u524D\uFF0C\u8FD8\u8981\u8BFB get_turns\uFF09\u2192 new_chat() \u628A\u539F\u5BF9\u8BDD\u5B58\u6863\u8FDB\u5386\u53F2
    # \u62BD\u5C49 \u2192 set_turns \u91CD\u6C34\u5408 + \u786C\u9884\u7B97\u91CD\u7F6E \u2192 \u6A2A\u5E45\uFF08\u6B63\u6587\u5E26\u6458\u8981\uFF0C\u4FDD\u8BC1\u91CD\u5F00\u9762\u677F
    # \u91CD\u653E\u540E\u6A21\u578B\u4E0A\u4E0B\u6587\u4ECD\u662F\u6458\u8981\uFF09\u3002\u6838\u5FC3\u903B\u8F91\u4E0E CLI /compact \u5171\u7528\uFF08compact.R\uFF09\u3002
    shiny::observeEvent(input$btn_compact, {
      if (is.null(client)) {
        shiny::showNotification("\u9762\u677F\u521D\u59CB\u5316\u5931\u8D25\uFF0C\u6CA1\u6709\u53EF\u538B\u7F29\u7684\u4F1A\u8BDD\u3002", type = "error")
        return()
      }
      shiny::showModal(shiny::modalDialog(
        title = shiny::tagList(shiny::icon("compress"), "\u538B\u7F29\u4E0A\u4E0B\u6587\uFF1F"),
        shiny::p("\u5C06\u7528\u5F53\u524D\u6A21\u578B\u628A\u672C\u4F1A\u8BDD\uFF08\u542B\u5DE5\u5177\u8C03\u7528\u94FE\uFF09\u603B\u7ED3\u6210\u4E00\u4EFD\u6458\u8981\uFF08\u6D88\u8017 1 \u6B21\u8BF7\u6C42\uFF0C\u53EF\u80FD\u9700\u8981\u5341\u51E0\u79D2\u5230\u4E00\u5206\u949F\uFF09\uFF1A\u6A21\u578B\u4E0A\u4E0B\u6587\u66FF\u6362\u4E3A\u6458\u8981\uFF0C\u786C\u9884\u7B97\u91CD\u7F6E\uFF1B\u539F\u5BF9\u8BDD\u5B58\u5165\u5386\u53F2\u62BD\u5C49\u53EF\u968F\u65F6\u627E\u56DE\u3002"),
        footer = list(
          shiny::actionButton("dai_compact_ok", "\u786E\u8BA4\u538B\u7F29", class = "dai-btn-primary"),
          shiny::modalButton("\u53D6\u6D88")
        ),
        easyClose = TRUE
      ))
    })
    shiny::observeEvent(input$dai_compact_ok, {
      shiny::removeModal()
      if (is.null(client)) return()
      # 0.8 \u8FDB\u5EA6\u53CD\u9988\uFF1A\u538B\u7F29\u662F\u540C\u6B65\u957F\u4EFB\u52A1\uFF08\u4E00\u6B21\u6A21\u578B\u8BF7\u6C42\uFF0C\u53EF\u80FD\u51E0\u5341\u79D2\uFF09\u3002Shiny \u5355\u7EBF\u7A0B\uFF0C
      # \u5FC5\u987B\u5148\u8BA9\u51FA\u4E8B\u4EF6\u5FAA\u73AF\u628A\u8FDB\u5EA6\u5F39\u7A97\u753B\u51FA\u6765\uFF0C\u518D\u7528 later \u56DE\u8C03\u5E72\u6D3B\u3002
      shiny::showModal(shiny::modalDialog(
        title = shiny::tagList(shiny::icon("compress"), "\u6B63\u5728\u538B\u7F29\u4E0A\u4E0B\u6587\u2026"),
        shiny::tagList(
          shiny::tags$span(class = "dai-spin"),
          shiny::p("\u6B63\u5728\u628A\u672C\u4F1A\u8BDD\uFF08\u542B\u5DE5\u5177\u8C03\u7528\u94FE\uFF09\u603B\u7ED3\u4E3A\u7ED3\u6784\u5316\u6458\u8981\uFF0C\u53EF\u80FD\u9700\u8981\u5341\u51E0\u79D2\u5230\u4E00\u5206\u949F\u2026\u2026")
        ),
        footer = NULL, easyClose = FALSE
      ))
      # \u5E72\u6D3B\u7684\u4E00\u6B21\u6027 observer\uFF1AinvalidateLater \u8BA9\u51FA\u4E8B\u4EF6\u5FAA\u73AF\u628A\u8FDB\u5EA6\u5F39\u7A97\u5148\u753B
      # \u51FA\u6765\uFF0C\u7136\u540E\u56DE\u5230\u54CD\u5E94\u5F0F\u4E0A\u4E0B\u6587\u91CC\u8DD1\u2014\u2014chat_mod$new_chat() \u4E0E rv_* \u90FD\u8981\u6C42
      # active reactive context\uFF08later \u56DE\u8C03\u91CC\u8C03\u7528\u9759\u9ED8\u5931\u8D25\uFF0C0.8 E2E \u5B9E\u6D4B
      # "Operation not allowed without an active reactive context"\uFF09\u3002
      o <- shiny::observe({
        shiny::invalidateLater(150, session)
        o$destroy() # \u4E00\u6B21\u6027\uFF08destroy() \u975E shiny \u5BFC\u51FA\uFF0Cobserver \u81EA\u5E26\u65B9\u6CD5\uFF09
        tryCatch({
          res <- tryCatch(
            .dairh_compact_summary(client, cfg),
            error = function(e) list(ok = FALSE, msg = conditionMessage(e))
          )
          shiny::removeModal(session = session)
          if (!isTRUE(res$ok)) {
            shiny::showNotification(paste0("\u538B\u7F29\u5931\u8D25\uFF1A", res$msg), type = "error", session = session)
            return()
          }
          # \u65E7\u8D26\u7ED3\u8F6C\uFF1Aturns \u5373\u5C06\u88AB\u6458\u8981\u66FF\u6362\uFF0Cget_tokens \u4F1A\u5F52\u96F6
          tryCatch({
            tbn <- tryCatch(client$get_tokens(), error = function(e) NULL)
            if (is.data.frame(tbn)) {
              carry_old <- rv_carry()
              rv_carry(c(carry_old[[1]] + sum(tbn$input %||% 0, na.rm = TRUE),
                         carry_old[[2]] + sum(tbn$output %||% 0, na.rm = TRUE)))
            }
          }, error = function(e) {
            shiny::showNotification(paste0("\u65E7\u8D26\u7ED3\u8F6C\u5931\u8D25\uFF1A", conditionMessage(e)), type = "warning", session = session)
          })
          # 0.8 \u627E\u56DE\u4FDD\u9669\uFF1Anew_chat \u662F"\u8BB0\u5F55\u539F\u5730\u91CD\u5F00"\uFF0C\u65E7\u8F6E\u6B21\u4E0D\u7559\u526F\u672C\u2014\u2014
          # \u5148\u628A\u5B58\u50A8\u4E09\u4EF6\u5957\u6574\u6811\u590D\u5236\u4E3A\u300C\uFF08\u538B\u7F29\u524D\u5907\u4EFD\uFF09\u300D\u6761\u76EE\uFF0C\u5931\u8D25\u5219\u8DF3\u8FC7\u3002
          backup <- tryCatch(.dairh_compact_backup_record(), error = function(e) {
            shiny::showNotification(paste0("\u538B\u7F29\u524D\u5907\u4EFD\u5931\u8D25\uFF1A", conditionMessage(e)), type = "warning", session = session)
            NULL
          })
          if (!is.null(chat_mod)) {
            tryCatch(chat_mod$new_chat(), error = function(e) {
              shiny::showNotification(paste0("\u5F52\u6863\u5F00\u65B0\u4F1A\u8BDD\u5931\u8D25\uFF1A", conditionMessage(e)), type = "error", session = session)
            })
          }
          tryCatch(
            .dairh_compact_apply(client, res$summary, res$n_old),
            error = function(e) {
              shiny::showNotification(paste0("\u6458\u8981\u91CD\u6C34\u5408\u5931\u8D25\uFF1A", conditionMessage(e)), type = "error", session = session)
            }
          )
          rv_tok(rv_tok() + 1L) # \u5F3A\u5236\u72B6\u6001\u680F\u91CD\u7B97
          rv_est(.dai_est_ctx(client) %||% 0) # \u538B\u7F29\u540E\u7684\u4E0A\u4E0B\u6587\u4F30\u7B97\u5360\u4F4D
          banner_bk <- if (!is.null(backup)) "\u539F\u5BF9\u8BDD\u5DF2\u5B8C\u6574\u5907\u4EFD\u4E3A\u5386\u53F2\u62BD\u5C49\u7684\u300C\uFF08\u538B\u7F29\u524D\u5907\u4EFD\uFF09\u300D\u6761\u76EE\uFF0C\u53EF\u968F\u65F6\u627E\u56DE\u3002" else
            "\u65E7\u5BF9\u8BDD\u8F6E\u6B21\u672A\u7559\u526F\u672C\uFF08\u5907\u4EFD\u5931\u8D25\uFF09\uFF1B\u5982\u9700\u7559\u5B58\uFF0C\u538B\u7F29\u524D\u8BF7\u81EA\u884C\u5904\u7406\u3002"
          tryCatch(shinychat::chat_append("chat", paste0(
            "**\u5DF2\u538B\u7F29\u4E0A\u4E0B\u6587**\u3000\u539F\u5BF9\u8BDD ", res$n_old,
            " \u8F6E \u2192 \u6458\u8981\u5DF2\u91CD\u6C34\u5408\uFF08\u786C\u9884\u7B97\u5DF2\u91CD\u7F6E\uFF09\u3002\n\n",
            banner_bk, "\n\n\u540E\u7EED\u5BF9\u8BDD\u6A21\u578B\u53EA\u770B\u8FD9\u4EFD\u6458\u8981\u3002\n\n---\n\n",
            res$summary
          ), session = session), error = function(e) {
            shiny::showNotification(paste0("\u538B\u7F29\u6A2A\u5E45\u5199\u5165\u5931\u8D25\uFF1A", conditionMessage(e)), type = "warning", session = session)
          })
        }, error = function(e) {
          tryCatch(shiny::removeModal(session = session), error = function(e2) NULL)
        })
      })
    })

    shiny::observeEvent(input$btn_explain, .dairh_chat_send(dairh_quick_prompt("explain")))
    shiny::observeEvent(input$btn_explain_sel, .dairh_chat_send(
      dairh_quick_prompt("explain_selection")
    ))
    shiny::observeEvent(input$btn_review, .dairh_chat_send(dairh_quick_prompt("review")))
    shiny::observeEvent(input$btn_docs,
      .dairh_chat_send(dairh_quick_prompt("docs", detail = "")))

    shiny::observeEvent(input$btn_settings, shiny::showModal(dairh_settings_modal(cfg)))

    dairh_settings_observers(input, output, session, cfg, standalone = FALSE)
  }
}

#' \u6784\u5EFA\u9762\u677F\uFF08ui + server\uFF09
#'
#' \u8FD4\u56DE `list(ui=, server=)`\uFF0C\u53EF\u76F4\u63A5\u4EA4\u7ED9 `shiny::runGadget()`\uFF0C
#' addin \u5185\u90E8\u4E5F\u662F\u8FD9\u4E48\u7528\u7684\u3002
#'
#' @param cfg \u914D\u7F6E\u5217\u8868\uFF08[dairh_config_get()]\uFF09
#' @return \u547D\u540D\u5217\u8868 `list(ui = <shiny \u9875\u9762\u5BF9\u8C61>, server = function(input, output, session))`
#' @examples
#' \dontrun{
#' app <- dairh_app()
#' shiny::runGadget(app$ui, app$server, viewer = shiny::paneViewer(500))
#' }
#' @export
dairh_app <- function(cfg = dairh_config_get()) {
  list(ui = dairh_panel_ui(cfg), server = .dairh_panel_server_impl(cfg))
}

# \u8BBE\u7F6E radio \u7684\u9009\u9879\u6784\u9020\uFF1A\u5B9E\u6D4B shiny \u5BF9\u547D\u540D choices \u63D0\u4EA4\u7684\u662F\u5192\u53F7\u53F3\u4FA7\u5B57\u7B26\u4E32\uFF0C
# \u540D\u5B57\u53EA\u4F5C\u663E\u793A\u6807\u7B7E\u3002\u8FD9\u91CC\u540D\u5B57/\u503C\u5206\u79BB\u6784\u9020\uFF0C\u4FDD\u8BC1\u63D0\u4EA4\u503C\u6C38\u8FDC\u662F\u5C0F\u5199\u89C4\u8303\u503C\uFF0C
# \u907F\u514D\u518D\u51FA\u73B0\u628A\u663E\u793A\u6587\u6848\u5B58\u8FDB config.json \u7684\u60C5\u51B5\uFF08\u66FE\u5BFC\u81F4 provider='Ollama' \u9762\u677F\u5168\u6B7B\uFF09\u3002
.dairh_provider_choices <- function() {
  vals <- c("ollama", "openai_compatible", "openai", "anthropic")
  names(vals) <- c("Ollama", "OpenAI \u517C\u5BB9 (DeepSeek / GLM / Kimi / ...)",
    "OpenAI Responses \u534F\u8BAE", "Anthropic Messages \u534F\u8BAE")
  vals
}

.dairh_runmode_choices <- function() {
  vals <- c("bg", "gadget")
  names(vals) <- c(
    "\u540E\u53F0\u8FD0\u884C\uFF08\u63A8\u8350\uFF0C\u4E0D\u5360\u7528\u63A7\u5236\u53F0\uFF09",
    "\u7ECF\u5178\u6A21\u5F0F\uFF08\u63A7\u5236\u53F0\u540C\u6B65\u5360\u7528\uFF0C\u5168\u529F\u80FD\u672C\u5730\u76F4\u8FDE\uFF09"
  )
  vals
}

# ---- \u8BBE\u7F6E\uFF08\u9762\u677F\u5185 modal \u4E0E\u72EC\u7ACB addin \u5171\u7528\uFF09------------------------------------

# \u5B57\u6BB5\u533A\uFF08\u4E24\u5904\u5171\u7528\uFF09\uFF1Amodal body / \u72EC\u7ACB\u9875\u9762 body \u90FD\u653E\u8FD9\u4E9B\u8F93\u5165\u63A7\u4EF6
.dairh_settings_fields <- function(cfg) {
  preset_keys <- names(DAI_LLM_PRESETS)
  default_preset <- if (length(preset_keys)) preset_keys[[1]] else NULL
  .dai_section <- function(icon_name, title, ...) {
    shiny::div(
      class = "dai-section",
      shiny::h6(shiny::icon(icon_name), title),
      ...
    )
  }
  shiny::tagList(
    .dai_section(
      "plug", "Provider \u4E0E\u6A21\u578B",
      shiny::selectInput("dai_preset",
        "\u9884\u8BBE\uFF08\u4E00\u952E\u56DE\u586B base_url \u4E0E\u6A21\u578B\uFF09",
        choices = preset_keys, selected = default_preset
      ),
      shiny::radioButtons("dai_provider", "Provider",
        choices = .dairh_provider_choices(),
        selected = .dairh_norm_provider(cfg$provider), inline = TRUE
      ),
      shiny::textInput("dai_base_url", "base_url", value = cfg$base_url %||% ""),
      shiny::div(
        style = "display:flex;gap:6px;align-items:flex-end;",
        shiny::div(
          style = "flex:1;",
          shiny::textInput("dai_model", "\u6A21\u578B\u540D", value = cfg$model %||% "")
        ),
        shiny::div(
          shiny::actionButton("dai_btn_models", "\u5217\u51FA\u6A21\u578B")
        )
      ),
      shiny::uiOutput("dai_model_pick"),
      shiny::numericInput("dai_context_window",
        "\u4E0A\u4E0B\u6587\u7A97\u53E3\uFF08tokens\uFF1B\u7F51\u5173\u4E00\u822C\u4E0D\u4F1A\u81EA\u52A8\u544A\u77E5\uFF0C\u7559\u7A7A = \u672A\u77E5\uFF0C\u6807\u9898\u680F\u53EA\u663E\u793A\u5360\u7528\uFF09",
        value = suppressWarnings(cfg$context_window %||% NA),
        min = 1000, max = 1e8, step = 1000
      ),
      shiny::numericInput("dai_compact_hint",
        "\u538B\u7F29\u63D0\u793A\u9608\u503C\uFF08\u5360\u7528/\u7A97\u53E3\uFF0C0 = \u5173\uFF0C0~1\uFF09",
        value = suppressWarnings(as.numeric(cfg$compact_hint %||% 0.7)),
        min = 0, max = 1, step = 0.05
      ),
      shiny::passwordInput("dai_key",
        "API Key\uFF08Ollama \u53EF\u7559\u7A7A\uFF1BDeepSeek \u7B49\u586B\u5B98\u65B9 key\uFF09",
        value = cfg$api_key %||% ""
      ),
      shiny::textInput("dai_key_env",
        "API Key \u73AF\u5883\u53D8\u91CF\u540D\uFF08\u82E5\u586B\u4E86 key \u5219\u5FFD\u7565\u6B64\u9879\uFF09",
        value = cfg$api_key_env %||% ""
      )
    ),
    .dai_section(
      "sliders", "\u8FD0\u884C\u4E0E\u5B89\u5168",
      shiny::radioButtons("dai_run_mode", "\u8FD0\u884C\u6A21\u5F0F",
        choices = .dairh_runmode_choices(),
        selected = .dairh_norm_run_mode(cfg$run_mode %||% "bg"), inline = TRUE
      ),
      shiny::selectInput("dai_mode", "\u9ED8\u8BA4\u4F1A\u8BDD\u6A21\u5F0F\uFF08\u65B0\u4F1A\u8BDD\u751F\u6548\uFF1B\u9762\u677F\u5934\u90E8\u6309\u94AE\u53EF\u70ED\u5207\uFF09",
        choices = c("\u6784\u5EFA\uFF08\u5168\u5DE5\u5177\uFF09" = "build", "\u8BA1\u5212\uFF08\u53EA\u8BFB\u8C03\u7814\uFF0C\u4EA4\u4ED8\u8BA1\u5212\uFF09" = "plan"),
        selected = .dairh_norm_mode(cfg$mode %||% "build")
      ),
      shiny::fluidRow(
        shiny::column(4, shiny::numericInput("dai_temp",
          "temperature\uff08\u7559\u7A7A = \u4E0D\u53D1\u9001\uFF1B\u90E8\u5206\u6A21\u578B\u62D2\u6536\uFF09",
          value = suppressWarnings(as.numeric(cfg$temperature %||% 0.7)),
          min = 0, max = 2, step = 0.1
        )),
        shiny::column(4, shiny::numericInput("dai_max_steps", "Agent \u6700\u5927\u5DE5\u5177\u6B65\u6570",
          value = cfg$max_steps %||% 12, min = 3, max = 60, step = 1
        )),
        shiny::column(4, shiny::selectInput("dai_effort", "\u601D\u8003\u5F3A\u5EA6",
          choices = c("\u5173\uFF08\u4E0D\u53D1\u9001\uFF09" = "", "\u4F4E" = "low", "\u4E2D" = "medium", "\u9AD8" = "high"),
          selected = .dairh_norm_effort(cfg$reasoning_effort %||% "")
        ))
      ),
      shiny::checkboxInput("dai_allow_edit",
        "\u5141\u8BB8 Agent \u8BFB\u5199\u6587\u4EF6\uFF08edit_file / create_file\uFF09",
        value = isTRUE(cfg$allow_edit)
      ),
      shiny::checkboxInput("dai_allow_run",
        "\u5141\u8BB8 Agent \u8FD0\u884C R \u4EE3\u7801\uFF08callr \u5B50\u8FDB\u7A0B\uFF09",
        value = isTRUE(cfg$allow_run)
      ),
      shiny::checkboxInput("dai_restrict",
        "\u6587\u4EF6\u64CD\u4F5C\u9650\u5236\u5728\u9879\u76EE/\u5DE5\u4F5C\u76EE\u5F55\u5185",
        value = isTRUE(cfg$restrict_paths)
      )
    ),
    .dai_section(
      "comment", "\u9AD8\u7EA7",
      shiny::textAreaInput("dai_extra",
        "\u9644\u52A0\u7CFB\u7EDF\u63D0\u793A\uFF08\u53EF\u9009\uFF0C\u8FFD\u52A0\u5230 Agent \u89C4\u5219\u540E\u9762\uFF09",
        value = cfg$system_prompt_extra %||% "", height = "70px"
      ),
      shiny::checkboxInput("dai_project_brief",
        "\u9879\u76EE\u6982\u89C8\uFF08\u65B0\u4F1A\u8BDD\u7CFB\u7EDF\u63D0\u793A\u81EA\u52A8\u5E26 git \u5FEB\u7167 + \u76EE\u5F55\u6811 + \u5DE5\u4F5C\u533A\u6458\u8981\uFF09",
        value = isTRUE(cfg$project_brief)
      ),
      shiny::checkboxInput("dai_show_thinking",
        "\u663E\u793A\u601D\u8003\u8FC7\u7A0B\uFF08\u91CD\u5F00\u9762\u677F\u751F\u6548\uFF09",
        value = isTRUE(cfg$show_thinking %||% TRUE)
      ),
      shiny::textInput("dai_bg",
        "\u9762\u677F\u80CC\u666F\u56FE\uFF08\u672C\u5730\u6587\u4EF6\u8DEF\u5F84\u6216 http(s) URL\uFF1B\u7559\u7A7A = \u5185\u7F6E\u591C\u6A31\uFF09",
        value = cfg$bg_image %||% ""
      ),
      shiny::fileInput("dai_bg_file",
        "\u2026\u6216\u4ECE\u7535\u8111\u9009\u56FE\uFF08\u9009\u5B8C\u70B9\u4FDD\u5B58\uFF1B\u526F\u672C\u5B58\u5165 daiRH \u6570\u636E\u76EE\u5F55\uFF0C\u2264 8MB\uFF09",
        accept = "image/*", buttonLabel = "\u6D4F\u89C8..."
      ),
      shiny::textInput("dai_mascot",
        "\u9762\u677F\u5DE6\u4FA7\u5409\u7965\u7269\u56FE\uFF08\u672C\u5730\u8DEF\u5F84\u6216 http(s) URL\uFF1B\u7559\u7A7A = \u5185\u7F6E\u5C0F\u673A\u5668\u4EBA\uFF09",
        value = cfg$mascot %||% ""
      ),
      shiny::fileInput("dai_mascot_file",
        "\u2026\u6216\u4ECE\u7535\u8111\u9009\u5409\u7965\u7269\u56FE\uFF08\u9009\u5B8C\u70B9\u4FDD\u5B58\uFF1B\u526F\u672C\u5B58\u5165 daiRH \u6570\u636E\u76EE\u5F55\uFF0C\u2264 8MB\uFF09",
        accept = "image/*", buttonLabel = "\u6D4F\u89C8..."
      ),
      shiny::textInput("dai_tools_profile",
        "\u5DE5\u5177\u811A\u672C\uFF08tools_profile\uFF0C\u7EDD\u5BF9\u8DEF\u5F84\uFF1B\u542F\u52A8\u65F6 source\uFF0C\u53EF\u6CE8\u518C\u81EA\u5B9A\u4E49\u5DE5\u5177/\u94A9\u5B50\uFF09",
        value = cfg$tools_profile %||% ""
      ),
      shiny::checkboxInput("dai_trace",
        "\u8BB0\u5F55\u5DE5\u5177\u8C03\u7528\u8F68\u8FF9\uFF08trace\uFF0Cdairh_trace() \u53EF\u67E5\uFF09",
        value = isTRUE(cfg$trace)
      ),
      shiny::checkboxInput("dai_history",
        "\u4F1A\u8BDD\u5386\u53F2\u62BD\u5C49\uFF08\u4EC5\u540E\u53F0\u9762\u677F\uFF1B\u591A\u4F1A\u8BDD\u5207\u6362\uFF0C\u91CD\u5F00\u81EA\u52A8\u7EED\u63A5\uFF09",
        value = isTRUE(cfg$history)
      ),
      shiny::checkboxInput("dai_history_title",
        "\u4F1A\u8BDD\u81EA\u52A8\u547D\u540D\uFF08LLM \u770B\u524D\u4E24\u8F6E\u5BF9\u8BDD\u8D77\u6807\u9898\uFF0C\u591A\u4E00\u6B21\u8C03\u7528\uFF09",
        value = isTRUE(cfg$history_title)
      ),
      shiny::textInput("dai_history_dir",
        "\u4F1A\u8BDD\u5386\u53F2\u76EE\u5F55\uFF08\u7559\u7A7A = \u9ED8\u8BA4\u7528\u6237\u6570\u636E\u76EE\u5F55\uFF1B\u6539\u540E\u65E7\u4F1A\u8BDD\u4E0D\u4E22\uFF0C\u62BD\u5C49\u6307\u5411\u65B0\u76EE\u5F55\uFF09",
        value = cfg$history_dir %||% ""
      ),
      shiny::textInput("dai_trace_dir",
        "\u5DE5\u5177\u8F68\u8FF9\u76EE\u5F55\uFF08\u7559\u7A7A = \u9ED8\u8BA4 cache \u76EE\u5F55\uFF09",
        value = cfg$trace_dir %||% ""
      ),
      shiny::checkboxInput("dai_allow_subagent",
        "\u5141\u8BB8\u5B50\u4EE3\u7406\u59D4\u6D3E\uFF08delegate_task\uFF1B\u6DF1\u5EA6\u9501 1 \u5C42\uFF0C\u72EC\u7ACB\u786C\u9884\u7B97\uFF09",
        value = isTRUE(cfg$allow_subagent)
      ),
      shiny::numericInput("dai_subagent_steps",
        "\u5B50\u4EE3\u7406\u5355\u8F6E\u786C\u6B65\u6570\uFF08subagent_max_steps\uFF09",
        value = cfg$subagent_max_steps %||% 8, min = 1, max = 60, step = 1
      ),
      shiny::textInput("dai_delegate_model",
        "\u5B50\u4EE3\u7406\u6A21\u578B\uFF08delegate_model\uFF1B\u7559\u7A7A = \u4E3B\u6A21\u578B\uFF0C\u91CD\u5F00\u9762\u677F\u751F\u6548\uFF09",
        value = cfg$delegate_model %||% ""
      ),
      shiny::textInput("dai_title_model",
        "\u8F7B\u91CF\u6A21\u578B\u8D77\u6807\u9898\uFF08title_model\uFF1B\u7559\u7A7A = \u4E3B\u6A21\u578B\uFF0C\u91CD\u5F00\u9762\u677F\u751F\u6548\uFF09",
        value = cfg$title_model %||% ""
      )
    )
  )
}

# modal \u7248\u672C\uFF08\u9762\u677F\u5185\u9F7F\u8F6E\u6253\u5F00\uFF09
dairh_settings_modal <- function(cfg) {
  shiny::modalDialog(
    title = shiny::tagList(shiny::icon("gear"), "DaiRH \u8BBE\u7F6E"),
    shiny::tagList(.dairh_settings_fields(cfg)),
    footer = list(
      shiny::actionButton("dai_save", "\u4FDD\u5B58", class = "dai-btn-primary"),
      shiny::modalButton("\u53D6\u6D88")
    ),
    easyClose = TRUE, size = "m"
  )
}

# \u72EC\u7ACB\u9875\u9762\u7248\u672C\uFF08\u8BBE\u7F6E addin\uFF09
dairh_settings_page_ui <- function(cfg) {
  shiny::fluidPage(
    shiny::tags$style(shiny::HTML(.dai_panel_css())),
    shinyjs::useShinyjs(),
    shiny::div(
      class = "dai-head",
      shiny::span(class = "dai-title", shiny::icon("gear"), "DaiRH \u8BBE\u7F6E")
    ),
    shiny::div(
      class = "dai-page-wrap",
      shiny::div(
        class = "dai-page-card",
        .dairh_settings_fields(cfg),
        shiny::div(
          shiny::actionButton("dai_save", "\u4FDD\u5B58", class = "dai-btn-primary"),
          shiny::p(style = "color:#9aa3b2;margin-top:8px",
            "\u4FDD\u5B58\u540E\u81EA\u52A8\u5173\u95ED\uFF1B\u9762\u677F\u4E0B\u6B21\u6253\u5F00\u751F\u6548\u3002")
        )
      )
    )
  )
}

# \u8BBE\u7F6E\u5171\u7528\u903B\u8F91\uFF1A\u9884\u8BBE\u56DE\u586B / \u5217\u6A21\u578B / \u4FDD\u5B58
dairh_settings_observers <- function(input, output, session, cfg, standalone = FALSE) {
  # \u80CC\u666F\u56FE fileInput \u4E0A\u9650\uFF08shiny \u9ED8\u8BA4 5MB\uFF0C\u653E\u5BBD\u5230 10MB \u4EE5\u8986\u76D6 8MB \u6821\u9A8C\uFF09
  if (getOption("shiny.maxRequestSize", 0) < 10 * 1024^2) {
    options(shiny.maxRequestSize = 10 * 1024^2)
  }
  preset_keys <- names(DAI_LLM_PRESETS)
  default_preset <- if (length(preset_keys)) preset_keys[[1]] else NULL

  shiny::observeEvent(input$dai_preset, {
    p <- DAI_LLM_PRESETS[[input$dai_preset]]
    if (is.null(p)) return()
    shiny::updateRadioButtons(session, "dai_provider", selected = p$provider)
    shiny::updateTextInput(session, "dai_base_url", value = p$base_url)
    shiny::updateTextInput(session, "dai_model", value = p$model)
    # \u5207\u9884\u8BBE\u540E\u6E05\u6389\u4E0A\u4E00\u8F6E"\u68C0\u6D4B\u5230/\u5185\u7F6E"\u7684\u6A21\u578B\u9009\u62E9 UI\uFF0C\u907F\u514D\u6E05\u5355\u4E0E\u65B0\u7AEF\u70B9\u9519\u4F4D\uFF080.6\uFF09
    output$dai_model_pick <- shiny::renderUI(NULL)
  })

  shiny::observeEvent(input$dai_btn_models, {
    tmp <- list(
      provider = input$dai_provider,
      base_url = input$dai_base_url,
      api_key = input$dai_key,
      api_key_env = input$dai_key_env
    )
    ms <- tryCatch(dairh_list_models(tmp), error = function(e) {
      shiny::showNotification(paste0("\u83B7\u53D6\u6A21\u578B\u5217\u8868\u5931\u8D25\uFF1A", conditionMessage(e)),
        type = "error"
      )
      character(0)
    })
    if (!length(ms)) {
      # 0.6 \u56DE\u9000\uFF1A\u7AEF\u70B9\u672A\u5B9E\u73B0 GET /models\uFF08\u5982\u6309\u6B21\u8BA1\u8D39\u7F51\u5173\uFF09\u65F6\uFF0C\u5F53\u524D\u9884\u8BBE\u82E5\u5E26
      # \u5185\u7F6E\u6A21\u578B\u6E05\u5355\u5219\u76F4\u63A5\u7ED9\u51FA\uFF0C\u70B9\u9009\u540E\u56DE\u586B\u6A21\u578B\u540D\u8F93\u5165\u6846\u3002
      pm <- DAI_LLM_PRESETS[[input$dai_preset]]$models %||% character(0)
      if (length(pm)) {
        shiny::showNotification(
          "\u7AEF\u70B9\u672A\u63D0\u4F9B\u6A21\u578B\u5217\u8868 API\uFF0C\u5DF2\u7ED9\u51FA\u8BE5\u9884\u8BBE\u7684\u5185\u7F6E\u6A21\u578B\u6E05\u5355\u3002", type = "message"
        )
        output$dai_model_pick <- shiny::renderUI({
          shiny::selectInput(
            "dai_model_pick_sel", "\u9884\u8BBE\u5185\u7F6E\u6A21\u578B\uFF1A",
            choices = pm,
            selected = if (input$dai_model %in% pm) input$dai_model else pm[[1]]
          )
        })
        return()
      }
      shiny::showNotification(
        "\u7AEF\u70B9\u4E0A\u6CA1\u53D6\u5230\u6A21\u578B\u5217\u8868\uFF08\u7F51\u7EDC\u4E0D\u901A / \u4E0D\u662F\u517C\u5BB9\u7AEF\u70B9 / Key \u6CA1\u586B\u5BF9\uFF09\u3002\u53EF\u624B\u52A8\u8F93\u5165\u6A21\u578B\u540D\u3002",
        type = "warning"
      )
      return()
    }
    output$dai_model_pick <- shiny::renderUI({
      shiny::selectInput(
        "dai_model_pick_sel", paste0("\u68C0\u6D4B\u5230 ", length(ms), " \u4E2A\u6A21\u578B\uFF1A"),
        choices = ms, selected = if (input$dai_model %in% ms) input$dai_model else ms[[1]]
      )
    })
  })
  shiny::observeEvent(input$dai_model_pick_sel, {
    shiny::updateTextInput(session, "dai_model", value = input$dai_model_pick_sel)
  })

  shiny::observeEvent(input$dai_save, {
    dairh_config_set(
      provider = .dairh_norm_provider(input$dai_provider),
      base_url = input$dai_base_url,
      model = input$dai_model,
      api_key = input$dai_key %||% "",
      api_key_env = input$dai_key_env %||% "",
      temperature = input$dai_temp,
      reasoning_effort = .dairh_norm_effort(input$dai_effort %||% ""),
      max_steps = input$dai_max_steps,
      run_mode = .dairh_norm_run_mode(input$dai_run_mode),
      mode = .dairh_norm_mode(input$dai_mode %||% "build"),
      allow_edit = isTRUE(input$dai_allow_edit),
      allow_run = isTRUE(input$dai_allow_run),
      restrict_paths = isTRUE(input$dai_restrict),
      system_prompt_extra = input$dai_extra %||% "",
      project_brief = isTRUE(input$dai_project_brief),
      bg_image = {
        # \u4ECE\u7535\u8111\u9009\u56FE\u4F18\u5148\uFF1A\u628A\u4E34\u65F6\u4E0A\u4F20\u62F7\u8FDB daiRH \u6570\u636E\u76EE\u5F55\uFF08fileInput \u7684\u4E34\u65F6\u6587\u4EF6
        # \u4F1A\u8BDD\u7ED3\u675F\u5373\u5220\uFF0C\u76F4\u63A5\u5B58\u8DEF\u5F84\u4E0B\u6B21\u9762\u677F\u5C31\u5931\u6548\u4E86\uFF09\uFF0C\u8DEF\u5F84\u624D\u53EF\u6301\u4E45\u5316
        bg <- trimws(input$dai_bg %||% "")
        up <- input$dai_bg_file
        if (!is.null(up) && length(up$datapath) > 0 &&
            !is.na(up$datapath) && nzchar(up$datapath)) {
          ok <- tryCatch({
            ext <- tolower(tools::file_ext(up$name))
            if (!ext %in% c("svg", "png", "jpeg", "jpg", "webp", "gif", "bmp")) {
              stop("\u683C\u5F0F\u4E0D\u652F\u6301\uFF08\u9700 svg/png/jpg/webp/gif/bmp\uFF09")
            }
            if (up$size > 8e6) stop("\u56FE\u7247\u8D85\u8FC7 8MB \u4E0A\u9650")
            d <- file.path(tools::R_user_dir("daiRH", "data"), "backgrounds")
            dir.create(d, recursive = TRUE, showWarnings = FALSE)
            dest <- file.path(d, paste0(
              "bg-", format(Sys.time(), "%Y%m%d-%H%M%S"), ".", ext))
            if (!file.copy(up$datapath, dest, overwrite = TRUE)) {
              stop("\u62F7\u8D1D\u5230\u6570\u636E\u76EE\u5F55\u5931\u8D25")
            }
            dest
          }, error = function(e) {
            shiny::showNotification(
              paste0("\u80CC\u666F\u56FE\u5904\u7406\u5931\u8D25\uFF1A", conditionMessage(e)), type = "error"
            )
            NULL
          })
          if (!is.null(ok)) bg <- ok
        }
        bg
      },
      mascot = {
        # \u4ECE\u7535\u8111\u9009\u56FE\u4F18\u5148\uFF1A\u526F\u672C\u5B58\u5165 daiRH \u6570\u636E\u76EE\u5F55 mascots/\uFF08\u540C bg_image \u6A21\u5F0F\uFF0C
        # fileInput \u7684\u4E34\u65F6\u6587\u4EF6\u4F1A\u8BDD\u7ED3\u675F\u5373\u5220\uFF0C\u5B58\u8DEF\u5F84\u624D\u80FD\u6301\u4E45\u5316\uFF09
        ms <- trimws(input$dai_mascot %||% "")
        up <- input$dai_mascot_file
        if (!is.null(up) && length(up$datapath) > 0 &&
            !is.na(up$datapath) && nzchar(up$datapath)) {
          ok <- tryCatch({
            ext <- tolower(tools::file_ext(up$name))
            if (!ext %in% c("svg", "png", "jpeg", "jpg", "webp", "gif", "bmp")) {
              stop("\u683C\u5F0F\u4E0D\u652F\u6301\uFF08\u9700 svg/png/jpg/webp/gif/bmp\uFF09")
            }
            if (up$size > 8e6) stop("\u56FE\u7247\u8D85\u8FC7 8MB \u4E0A\u9650")
            d <- file.path(tools::R_user_dir("daiRH", "data"), "mascots")
            dir.create(d, recursive = TRUE, showWarnings = FALSE)
            dest <- file.path(d, paste0(
              "mascot-", format(Sys.time(), "%Y%m%d-%H%M%S"), ".", ext))
            if (!file.copy(up$datapath, dest, overwrite = TRUE)) {
              stop("\u62F7\u8D1D\u5230\u6570\u636E\u76EE\u5F55\u5931\u8D25")
            }
            dest
          }, error = function(e) {
            shiny::showNotification(
              paste0("\u5409\u7965\u7269\u56FE\u5904\u7406\u5931\u8D25\uFF1A", conditionMessage(e)), type = "error"
            )
            NULL
          })
          if (!is.null(ok)) ms <- ok
        }
        ms
      },
      context_window = {
        cw <- suppressWarnings(as.numeric(input$dai_context_window))
        if (length(cw) != 1L || is.na(cw) || cw < 1) NA_real_ else cw
      },
      compact_hint = {
        h <- suppressWarnings(as.numeric(input$dai_compact_hint))
        if (length(h) != 1L || is.na(h) || h < 0 || h > 1) 0.7 else h
      },
      trace = isTRUE(input$dai_trace),
      trace_dir = trimws(input$dai_trace_dir %||% ""),
      tools_profile = trimws(input$dai_tools_profile %||% ""),
      history = isTRUE(input$dai_history),
      history_dir = trimws(input$dai_history_dir %||% ""),
      history_title = isTRUE(input$dai_history_title),
      allow_subagent = isTRUE(input$dai_allow_subagent),
      subagent_max_steps = {
        s <- suppressWarnings(as.integer(input$dai_subagent_steps %||% 8L))
        if (length(s) != 1L || is.na(s) || s < 1L) 8L else s
      },
      delegate_model = trimws(input$dai_delegate_model %||% ""),
      title_model = trimws(input$dai_title_model %||% ""),
      show_thinking = isTRUE(input$dai_show_thinking)
    )
    if (standalone) {
      shiny::stopApp()
    } else {
      shiny::removeModal()
      shiny::showNotification(
        "\u914D\u7F6E\u5DF2\u4FDD\u5B58\u3002\u5173\u95ED\u5E76\u91CD\u65B0\u6253\u5F00 DaiRH \u9762\u677F\u540E\u751F\u6548\u3002", type = "message"
      )
    }
  })
}
