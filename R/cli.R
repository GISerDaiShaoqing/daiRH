# DaiRH 控制台 CLI（claude-code 风格）------------------------------------------
# 在 RStudio 控制台/任意 R 会话里直接与 agent 对话：readline 循环 + ellmer 流式
# 输出 + 工具调用过程回显。与面板互不依赖（控制台跑 CLI 时，bg 面板子进程照常独立）。
# 代价：运行期间控制台被占用（同 gadget 模式）；Ctrl+C 或 /exit 退出。

# 启动横幅（ASCII 大字 + 状态行）。动画只在交互式会话播放；
# options(daiRH.cli_banner_speed = 0) 可关闭延迟。
.dai_banner <- function(cfg) {
  art <- c(
    "  \u2588\u2588\u2588\u2588\u2588\u2588\u2557  \u2588\u2588\u2588\u2588\u2588\u2557 \u2588\u2588\u2557\u2588\u2588\u2588\u2588\u2588\u2588\u2557 \u2588\u2588\u2557  \u2588\u2588\u2557",
    "  \u2588\u2588\u2554\u2550\u2550\u2588\u2588\u2557\u2588\u2588\u2554\u2550\u2550\u2588\u2588\u2557\u2588\u2588\u2551\u2588\u2588\u2554\u2550\u2550\u2588\u2588\u2557\u2588\u2588\u2551  \u2588\u2588\u2551",
    "  \u2588\u2588\u2551  \u2588\u2588\u2551\u2588\u2588\u2588\u2588\u2588\u2588\u2588\u2551\u2588\u2588\u2551\u2588\u2588\u2588\u2588\u2588\u2588\u2554\u2557\u2588\u2588\u2588\u2588\u2588\u2588\u2588\u2551",
    "  \u2588\u2588\u2551  \u2588\u2588\u2551\u2588\u2588\u2554\u2550\u2550\u2588\u2588\u2551\u2588\u2588\u2551\u2588\u2588\u2554\u2550\u2550\u2588\u2588\u2557\u2588\u2588\u2554\u2550\u2550\u2588\u2588\u2551",
    "  \u2588\u2588\u2588\u2588\u2588\u2588\u2554\u2557\u2588\u2588\u2551  \u2588\u2588\u2551\u2588\u2588\u2551\u2588\u2588\u2551  \u2588\u2588\u2551\u2588\u2588\u2551  \u2588\u2588\u2551",
    "  \u255A\u2550\u2550\u2550\u2550\u2550\u255D \u255A\u2550\u255D  \u255A\u2550\u255D\u255A\u2550\u255D\u255A\u2550\u255D  \u255A\u2550\u255D\u255A\u2550\u255D  \u255A\u2550\u255D"
  )
  speed <- getOption("daiRH.cli_banner_speed")
  if (is.null(speed)) speed <- 0.05
  speed <- as.numeric(speed)
  if (!is.finite(speed) || speed < 0) speed <- 0
  animate <- interactive() && speed > 0
  col <- if (requireNamespace("crayon", quietly = TRUE)) {
    tryCatch(crayon::cyan, error = function(e) identity)
  } else identity
  for (l in art) {
    cat(col(l), "\n", sep = "")
    if (animate) Sys.sleep(speed)
  }
  tools_txt <- tryCatch({
    n <- length(dairh_agent_tools(cfg))
    sprintf("%d \u4E2A", n)
  }, error = function(e) "?")
  budget <- suppressWarnings(as.integer(cfg$max_steps %||% 12))
  if (!is.finite(budget) || budget < 1) budget <- 12L
  cat(
    "\n",
    "  \u2500\u2500 provider: ", cfg$provider %||% "?",
    "  \u00B7 \u6A21\u578B: ", cfg$model %||% "?", "\n",
    "  \u2500\u2500 \u5DE5\u5177: ", tools_txt,
    " \u00B7 \u5355\u8F6E\u9884\u7B97: ", budget, " \u6B65",
    " \u00B7 trace: ", if (isTRUE(cfg$trace)) "\u5F00" else "\u5173", "\n",
    "  \u2500\u2500 \u76F4\u63A5\u8F93\u5165\u4EFB\u52A1\u5F00\u59CB\u5BF9\u8BDD\uFF1B/help \u770B\u547D\u4EE4\uFF0C/exit \u9000\u51FA\uFF08Ctrl+C \u4E5F\u53EF\uFF09\n\n",
    sep = ""
  )
  invisible(NULL)
}

.dai_cli_prompt <- function() {
  if (requireNamespace("crayon", quietly = TRUE)) {
    tryCatch(paste0(crayon::cyan("daiRH"), crayon::silver(" \u276F ")),
      error = function(e) "daiRH > ")
  } else {
    "daiRH > "
  }
}

# /命令：返回 "exit" 表示退出循环，"reset" 表示重建会话，其余为已处理
.dai_cli_command <- function(line) {
  parts <- strsplit(trimws(line), "[[:space:]]+")[[1]]
  cmd <- tolower(parts[[1]] %||% "")
  switch(cmd,
    "/exit" = , "/quit" = , "/q" = , "/bye" = "exit",
    "/clear" = , "/new" = "reset",
    "/tools" = {
      lt <- dairh_list_tools()
      cat(sprintf("  %-18s %-10s %s\n", "name", "source", "description"))
      for (i in seq_len(nrow(lt))) {
        cat(sprintf("  %-18s %-10s %s\n",
          lt$name[[i]], lt$source[[i]], .dai_clip(lt$description[[i]] %||% "", 60)))
      }
      "ok"
    },
    "/help" = {
      cat(
        "  /help            \u663E\u793A\u672C\u5E2E\u52A9\n",
        "  /clear           \u5F00\u65B0\u4F1A\u8BDD\uFF08\u6E05\u6A21\u578B\u5386\u53F2\uFF0C\u786C\u9884\u7B97\u5F52\u96F6\uFF09\n",
        "  /tools           \u5217\u51FA\u5F53\u524D\u5DE5\u5177\u6E05\u5355\uFF08\u542B\u81EA\u5B9A\u4E49\uFF09\n",
        "  /exit            \u9000\u51FA CLI\n",
        "  \u5176\u5B83\u6587\u5B57\u90FD\u4F5C\u4E3A\u4EFB\u52A1\u53D1\u7ED9 Agent\uFF1B\u5DE5\u5177\u8C03\u7528\u8FC7\u7A0B\u4F1A\u76F4\u63A5\u56DE\u663E\u5728\u63A7\u5236\u53F0\n",
        sep = ""
      )
      "ok"
    },
    {
      cat("  \u672A\u77E5\u547D\u4EE4: ", cmd, "\uFF08/help \u67E5\u770B\u53EF\u7528\u547D\u4EE4\uFF09\n", sep = "")
      "ok"
    }
  )
}

#' \u5728\u63A7\u5236\u53F0\u91CC\u76F4\u63A5\u4E0E DaiRH Agent \u5BF9\u8BDD\uFF08CLI \u6A21\u5F0F\uFF09
#'
#' claude-code \u98CE\u683C\uFF1A\u542F\u52A8\u6A2A\u5E45\uFF08\u5E26\u52A8\u753B\uFF09+ readline \u5FAA\u73AF + ellmer
#' \u6D41\u5F0F\u8F93\u51FA\uFF08\u5DE5\u5177\u8C03\u7528\u8FC7\u7A0B\u56DE\u663E\uFF09\u3002\u8FD0\u884C\u5728\u5F53\u524D R \u4F1A\u8BDD\uFF08RStudio
#' \u63A7\u5236\u53F0\u6216\u7EC8\u7AEF\uFF09\uFF0C\u671F\u95F4\u63A7\u5236\u53F0\u88AB\u5360\u7528\uFF1B`/exit` \u6216 Ctrl+C \u9000\u51FA\u3002
#' \u786C\u9884\u7B97/\u94A9\u5B50/trace \u4E0E\u9762\u677F\u5B8C\u5168\u540C\u4E00\u5957 harness\u3002
#'
#' @param cfg \u914D\u7F6E\u5217\u8868\uFF08[dairh_config_get()]\uFF09
#' @examples
#' \dontrun{
#' dairh_cli()                       # \u5F53\u524D\u914D\u7F6E
#' dairh_cli(dairh_config_get())     # \u540C\u4E0A
#' }
#' @export
dairh_cli <- function(cfg = dairh_config_get()) {
  .dai_banner(cfg)
  agent <- tryCatch(dairh_new_agent(cfg), error = function(e) {
    cat("\u521D\u59CB\u5316\u5931\u8D25\uFF1A", conditionMessage(e), "\n", sep = "")
    NULL
  })
  if (is.null(agent)) return(invisible(NULL))
  st <- attr(agent, ".dairh_state")

  repeat {
    line <- tryCatch(
      readline(prompt = .dai_cli_prompt()),
      interrupt = function(e) NULL,
      error = function(e) NULL
    )
    if (is.null(line)) {
      cat("\n\uFF08\u5DF2\u4E2D\u65AD\uFF0C\u9000\u51FA CLI\uFF09\n")
      break
    }
    line <- trimws(line)
    if (!nzchar(line)) next
    if (startsWith(line, "/")) {
      act <- .dai_cli_command(line)
      if (identical(act, "exit")) {
        cat("\u518D\u89C1\uFF01\n")
        break
      }
      if (identical(act, "reset")) {
        agent <- tryCatch(dairh_new_agent(cfg), error = function(e) agent)
        st <- attr(agent, ".dairh_state")
        cat("\u5DF2\u5F00\u65B0\u4F1A\u8BDD\uFF1A\u804A\u8BB0\u4E0E\u786C\u9884\u7B97\u5DF2\u91CD\u7F6E\u3002\n")
      }
      next
    }
    t0 <- Sys.time()
    # echo="output"（ellmer 用户界面默认档）：正文流式无前缀，工具调用渲染成
    # "● [tool call] ..." + "⏺ #> 结果预览"；echo="all" 会给正文加 "< " 前缀且更吵
    res <- tryCatch(
      agent$chat(line, echo = "output"),
      interrupt = function(e) {
        cat("\n\uFF08\u672C\u8F6E\u5DF2\u4E2D\u65AD\uFF1B\u82E5\u4E0B\u4E00\u8F6E\u62A5\u9519\uFF0C\u8BF7 /clear \u91CD\u7F6E\u4F1A\u8BDD\uFF09\n")
        NULL
      },
      error = function(e) e
    )
    if (inherits(res, "error")) {
      cat("\u9519\u8BEF\uFF1A", conditionMessage(res), "\n", sep = "")
      next
    }
    if (is.null(res)) next
    dur <- as.numeric(difftime(Sys.time(), t0, units = "secs"))
    nc <- if (is.environment(st)) st$n_calls %||% 0L else 0L
    bg <- if (is.environment(st)) st$budget %||% NA_integer_ else NA_integer_
    cat(
      if (requireNamespace("crayon", quietly = TRUE)) {
        tryCatch(paste0(crayon::silver(sprintf(
          "  \u2014 \u672C\u8F6E\u5DE5\u5177\u8C03\u7528 %s \u6B65 / \u9884\u7B97 %s \u00B7 \u7528\u65F6 %.1fs\uFF1B\u65B0\u4EFB\u52A1\u81EA\u52A8\u91CD\u7F6E\u9884\u7B97\n",
          nc, bg, dur))), error = function(e) sprintf(
          "  \u2014 \u672C\u8F6E\u5DE5\u5177\u8C03\u7528 %s \u6B65 / \u9884\u7B97 %s \u00B7 \u7528\u65F6 %.1fs\n",
          nc, bg, dur))
      } else {
        sprintf("  \u2014 \u672C\u8F6E\u5DE5\u5177\u8C03\u7528 %s \u6B65 / \u9884\u7B97 %s \u00B7 \u7528\u65F6 %.1fs\n",
          nc, bg, dur)
      }
    )
  }
  invisible(NULL)
}
