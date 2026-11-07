# DaiRH \u4F1A\u8BDD\u6A21\u5F0F\uFF08plan / build\uFF09-------------------------------------------------
# plan\uFF08\u8BA1\u5212\uFF09= \u53EA\u8BFB\u8C03\u7814\uFF1A\u8FD0\u884C\u65F6\u4ECE\u6700\u7EC8\u5DE5\u5177\u96C6\u7269\u7406\u88C1\u6389\u5199\u6587\u4EF6/\u6267\u884C/\u4EA4\u4ED8\u7C7B\u5DE5\u5177
#   \uFF08.dairh_plan_dropped_tools\uFF0C\u975E\u63D0\u793A\u8BCD\u529D\u544A\uFF09\uFF0C\u7CFB\u7EDF\u63D0\u793A\u8BCD\u6362\u6210"\u8C03\u7814 + \u4EA7\u51FA\u7ED3\u6784\u5316
#   \u8BA1\u5212"\u7684\u53E3\u5F84\uFF1Bdelegate_task \u4FDD\u7559\uFF08\u5B50\u4EE3\u7406\u7EE7\u627F\u540C\u4E00 cfg$mode\uFF0C\u5929\u7136\u53EA\u8BFB\uFF09\uFF0C
#   \u8BA1\u5212\u9636\u6BB5\u7684\u72EC\u7ACB\u8C03\u7814\u4E0D\u53D7\u5F71\u54CD\u3002
# build\uFF08\u6784\u5EFA\uFF09= \u5168\u5DE5\u5177\uFF0C\u4E3B\u53E3\u5F84\u3002
# \u9762\u677F\u5934\u90E8\u6309\u94AE\u4E0E\u63A7\u5236\u53F0 /plan /build \u90FD\u8D70 .dairh_set_mode() \u70ED\u5207\u6362\uFF1A\u540C\u4E00 state env
# \u91CD\u5EFA\u5DE5\u5177\u96C6 + client$set_system_prompt()/set_tools() \u539F\u5730\u6362\uFF08ellmer Chat \u662F R6\uFF0C
# shinychat \u7684\u8D77\u6807\u9898\u4E0E\u5386\u53F2\u91CD\u653E\u7528\u7684\u5C31\u662F\u8FD9\u4E24\u4E2A\u673A\u5236\uFF09\uFF0C\u5BF9\u8BDD\u4E0E\u786C\u9884\u7B97\u8BA1\u6570\u90FD\u4E0D\u4E22\uFF1B
# config \u7684 mode \u5B57\u6BB5\u53EA\u662F\u65B0\u4F1A\u8BDD\u7684\u9ED8\u8BA4\u503C\uFF0C\u70ED\u5207\u6362\u4E0D\u5199\u914D\u7F6E\u6587\u4EF6\u3002

# \u8BA1\u5212\u6A21\u5F0F\u88C1\u6389\u7684\u5185\u7F6E\u5DE5\u5177\uFF08\u4E0E dairh_agent_tools \u7684\u6CE8\u518C\u6E05\u5355\u5BF9\u5E94\uFF1B\u81EA\u5B9A\u4E49\u5DE5\u5177\u4E0D\u88C1\uFF0C
# \u5176\u526F\u4F5C\u7528\u7531\u7528\u6237\u81EA\u8D1F\uFF09
.dairh_plan_dropped_tools <- c(
  "create_file", "edit_file", "run_r_code", "show_plot", "show_html"
)

.dairh_is_plan_mode <- function(cfg) {
  identical(.dairh_norm_mode(cfg$mode %||% "build"), "plan")
}

# \u70ED\u5207\u6362\u6838\u5FC3\uFF1Acfg2 = cfg + mode \u8986\u76D6 \u2192 \u91CD\u5EFA\u5DE5\u5177\u96C6\uFF08\u590D\u7528\u540C\u4E00 state env\uFF09\u2192
# \u539F\u5730\u6362\u63D0\u793A\u8BCD\u4E0E\u5DE5\u5177\u96C6 \u2192 state$mode \u8BB0\u8D26 \u2192 trace \u5199 type="mode" \u4E8B\u4EF6\uFF08\u5BA1\u8BA1\u53EF\u8FFD\uFF09\u3002
# client \u5FC5\u987B\u662F dairh_new_agent() \u7684\u4EA7\u7269\uFF08\u5E26 .dairh_state \u5C5E\u6027\uFF09\u3002
.dairh_set_mode <- function(client, mode, cfg = dairh_config_get()) {
  mode <- .dairh_norm_mode(mode)
  st <- attr(client, ".dairh_state")
  if (is.null(st)) {
    stop("client \u4e0d\u662f dairh_new_agent() \u7684\u4ea7\u7269\uff08\u7f3a .dairh_state \u5c5e\u6027\uff09", call. = FALSE)
  }
  cfg2 <- cfg
  cfg2$mode <- mode
  tools <- dairh_agent_tools(cfg2, state = st)
  client$set_system_prompt(dairh_system_prompt(cfg2))
  client$set_tools(tools)
  st$mode <- mode
  .dairh_trace_write(st, list(
    ts = format(Sys.time(), "%Y-%m-%d %H:%M:%OS3"),
    pid = Sys.getpid(),
    agent = if (identical(st$tag, "sub")) "sub" else "main",
    type = "mode",
    mode = mode
  ))
  invisible(client)
}
