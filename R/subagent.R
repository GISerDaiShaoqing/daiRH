# DaiRH \u5B50\u4EE3\u7406\u59D4\u6D3E -------------------------------------------------------------
# \u4E3B Agent \u901A\u8FC7 delegate_task \u5DE5\u5177\u628A\u81EA\u5305\u542B\u7684\u5B50\u4EFB\u52A1\u4EA4\u7ED9\u4E00\u4E2A\u5168\u65B0\u7684 Chat\uFF1A
#   - \u4E0A\u4E0B\u6587\u9694\u79BB\uFF1A\u5B50\u4EE3\u7406\u53EA\u770B\u5230\u4EFB\u52A1\u63CF\u8FF0\uFF0C\u770B\u4E0D\u5230\u4E3B\u5BF9\u8BDD\uFF08\u4FDD\u62A4\u4E3B\u4E0A\u4E0B\u6587\u7A97\u53E3\uFF09
#   - \u5DE5\u5177\u96C6\u540C\u4E3B\u4F53\u4F46\u6392\u9664 delegate_task \u81EA\u8EAB\uFF08\u6DF1\u5EA6\u9501 1 \u5C42\uFF0C\u9632\u9012\u5F52\uFF09
#   - \u72EC\u7ACB\u786C\u9884\u7B97\uFF08cfg$subagent_max_steps\uFF09\uFF1B\u7236\u7EA7\u5929\u7136\u6D88\u8017 1 \u6B65\uFF08\u5305\u88C5\u5668\u81EA\u589E\uFF09
#   - \u540C\u6B65\u6267\u884C\uFF1A\u59D4\u6D3E\u671F\u95F4\u9762\u677F\u4E0D\u6D41\u5F0F\u56DE\u663E\u5B50\u8FC7\u7A0B\uFF08\u5DF2\u77E5\u8FB9\u754C\uFF0C\u6587\u6863\u8BF4\u660E\uFF09
# v1 \u7EA6\u675F\uFF1A\u4E0D\u652F\u6301\u5E76\u53D1\u59D4\u6D3E\uFF1B0.7 \u8D77\u5B50\u4EE3\u7406\u6A21\u578B\u53EF\u7528 cfg$delegate_model \u6307\u5B9A\uFF08\u7559\u7A7A\u6CBF\u7528\u4E3B\u914D\u7F6E\uFF09\u3002

# \u5B50\u4EE3\u7406\u7CFB\u7EDF\u63D0\u793A\u8BCD\uFF1A\u6BD4\u4E3B\u4F53\u77ED\u5F97\u591A\uFF0C\u5F3A\u8C03\u81EA\u4E3B\u5B8C\u6210 + \u76F4\u63A5\u8F93\u51FA\u7ED3\u679C
.dairh_subagent_prompt <- function(cfg = dairh_config_get()) {
  paste(c(
    "\u4F60\u662F DaiRH \u4E3B Agent \u59D4\u6D3E\u7684\u5B50\u4EE3\u7406\uFF08Sub-agent\uFF09\uFF0C\u53EA\u9762\u5BF9\u4E00\u6B21\u6027\u4EFB\u52A1\uFF1A",
    "- \u53EA\u505A\u4EFB\u52A1\u63CF\u8FF0\u91CC\u4EA4\u529E\u7684\u4E8B\uFF0C\u4E0D\u5C55\u5F00\u65E0\u5173\u5DE5\u4F5C\uFF1B\u5B8C\u6210\u540E\u76F4\u63A5\u8F93\u51FA\u7ED3\u679C\u672C\u8EAB\uFF08\u4E0D\u5BA2\u5957\u3001\u4E0D\u8BF7\u6C42\u786E\u8BA4\uFF09\u3002",
    "- \u5DE5\u5177\u4F7F\u7528\u89C4\u5219\u3001\u5B89\u5168\u8FB9\u754C\u4E0E\u4E3B Agent \u4E00\u81F4\uFF1A\u6587\u4EF6\u64CD\u4F5C\u9650\u9879\u76EE\u76EE\u5F55\uFF0Crun_r_code \u5728\u9694\u79BB\u5B50\u8FDB\u7A0B\u8DD1\uFF08\u6BCF\u6BB5\u4EE3\u7801\u81EA\u5E26 library()\uFF09\u3002",
    "- \u5168\u7A0B\u7B80\u4F53\u4E2D\u6587\uFF1B\u4EE3\u7801/\u62A5\u9519\u4FE1\u606F\u4FDD\u7559\u82F1\u6587\u539F\u6587\u3002\u8F93\u51FA\u7CBE\u7EC3\u7ED3\u6784\u5316\uFF0C\u91CD\u8981\u7ED3\u8BBA\u5148\u8BF4\u3002",
    "- \u5DE5\u5177\u8C03\u7528\u6709\u786C\u9884\u7B97\uFF0C\u6B65\u9AA4\u8981\u5408\u5E76\u7CBE\u7B80\uFF1B\u9884\u7B97\u5C06\u5C3D\u65F6\u76F4\u63A5\u7ED9\u51FA\u7ED3\u8BBA\u3002",
    if (isTRUE(cfg$restrict_paths)) {
      sprintf("- \u6587\u4EF6\u64CD\u4F5C\u88AB\u9650\u5236\u5728\uFF1A %s", dairh_base_dir())
    },
    sprintf("\u5DE5\u4F5C\u76EE\u5F55: %s\uFF0C%s\uFF0CR \u7248\u672C: %s",
      dairh_base_dir(), format(Sys.Date()), R.version.string)
  ), collapse = "\n")
}

# delegate_task \u5DE5\u5177\u4F53\uFF1A\u8D77\u5B50 Chat \u2192 \u6CE8\u518C\u6392\u9664\u81EA\u8EAB\u7684\u5DE5\u5177\u96C6 \u2192 \u540C\u6B65\u8DD1\u5B8C \u2192 \u6C47\u62A5\u3002
# \u8FD4\u56DE\u5B57\u7B26\u4E32\u7ED9\u4E3B\u6A21\u578B\uFF1B\u59D4\u6D3E\u8D77\u6B62\u5404\u5199\u4E00\u6761 trace\uFF08type=delegate\uFF09\u3002
.dairh_delegate_task <- function(task, cfg = dairh_config_get(), state = NULL) {
  task <- paste(as.character(task), collapse = "\n")
  if (!nzchar(trimws(task))) return("FAIL: task \u4E0D\u80FD\u4E3A\u7A7A\u3002")
  # \u53CC\u4FDD\u9669\uFF1A\u5DE5\u5177\u96C6\u5DF2\u6392\u9664\u81EA\u8EAB\uFF0C\u8FD9\u91CC\u518D\u62E6\u4EBA\u4E3A\u6784\u9020\u7684\u5B50\u4EE3\u7406\u5957\u5A03
  if (!is.null(state) && identical(state$tag, "sub")) {
    return("FAIL: \u5B50\u4EE3\u7406\u4E0D\u80FD\u518D\u59D4\u6D3E\u5B50\u4EE3\u7406\uFF08\u4EC5\u652F\u6301\u4E00\u5C42\uFF09\u3002")
  }
  steps <- suppressWarnings(as.integer(cfg$subagent_max_steps %||% 8L))
  if (length(steps) != 1L || is.na(steps) || steps < 1L) steps <- 8L

  sub_state <- .dairh_new_state(cfg)
  sub_state$budget <- steps
  sub_state$tag <- "sub"
  tools <- dairh_agent_tools(cfg, state = sub_state, exclude = "delegate_task")

  t0 <- Sys.time()
  .dairh_trace_write(state, list(
    ts = format(t0, "%Y-%m-%d %H:%M:%OS3"),
    pid = Sys.getpid(),
    agent = "main",
    type = "delegate",
    event = "start",
    task = .dai_clip(task, 400),
    sub_max_steps = steps
  ))
  # \u89C2\u6D4B\u6027\uFF1A\u5B50\u4EE3\u7406\u5199\u8FDB\u7236 trace \u6587\u4EF6\uFF08\u5355\u4E00\u65F6\u95F4\u7EBF\uFF0Cagent \u5217\u533A\u5206 main/sub\uFF09\u3002
  # start \u4E8B\u4EF6\u5DF2\u786E\u4FDD\u7236 state$trace_file \u5C31\u4F4D\uFF1B\u7236 trace \u5173\u95ED\u65F6\u4E24\u8005\u672C\u5C31\u4E0D\u5199\u3002
  sub_state$trace_file <- state$trace_file
  res <- tryCatch({
    # 0.7 delegate_model\uFF1A\u5B50\u4EE3\u7406\u53EF\u8D70\u8F7B\u91CF\u6A21\u578B\uFF1B\u7559\u7A7A\u6CBF\u7528\u4E3B\u914D\u7F6E\u3002
    # usage \u6F0F\u6597\u65E0\u9700\u6539\u2014\u2014dairh_client \u8BFB cfg$model\uFF0Cjsonl \u7684 model \u5B57\u6BB5\u81EA\u52A8\u8DDF\u968F\u3002
    sub_cfg <- cfg
    dm <- suppressWarnings(trimws(as.character(cfg$delegate_model %||% ""))[[1]])
    if (length(dm) == 1L && !is.na(dm) && nzchar(dm)) sub_cfg$model <- dm
    sub_client <- dairh_client(sub_cfg, system_prompt = .dairh_subagent_prompt(cfg))
    for (nm in names(tools)) sub_client$register_tool(tools[[nm]])
    sub_state$client <- sub_client
    res_text <- sub_client$chat(task)
    paste(as.character(res_text), collapse = "\n")
  }, error = function(e) paste0("FAIL: \u5B50\u4EE3\u7406\u6267\u884C\u5931\u8D25\uFF1A", conditionMessage(e)))
  dur <- as.numeric(difftime(Sys.time(), t0, units = "secs"))
  .dairh_trace_write(state, list(
    ts = format(Sys.time(), "%Y-%m-%d %H:%M:%OS3"),
    pid = Sys.getpid(),
    agent = "main",
    type = "delegate",
    event = "done",
    duration_s = round(dur, 3),
    result = .dai_clip(res, 400)
  ))
  if (is.character(res) && !startsWith(res, "FAIL")) {
    paste0("OK: \u5B50\u4EE3\u7406\u5DF2\u5B8C\u6210\uFF08\u7528\u65F6 ", round(dur, 1),
      " \u79D2\uFF09\u3002\u7ED3\u679C\uFF1A\n", .dai_clip(res, 4000))
  } else {
    res
  }
}
