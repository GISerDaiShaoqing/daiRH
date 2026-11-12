# DaiRH \u63A7\u5236\u53F0 CLI\uFF08claude-code \u98CE\u683C\uFF09------------------------------------------
# \u5728 RStudio \u63A7\u5236\u53F0/\u4EFB\u610F R \u4F1A\u8BDD\u91CC\u76F4\u63A5\u4E0E agent \u5BF9\u8BDD\uFF1Areadline \u5FAA\u73AF + ellmer \u6D41\u5F0F
# \u8F93\u51FA + \u5DE5\u5177\u8C03\u7528\u8FC7\u7A0B\u56DE\u663E\u3002\u4E0E\u9762\u677F\u4E92\u4E0D\u4F9D\u8D56\uFF08\u63A7\u5236\u53F0\u8DD1 CLI \u65F6\uFF0Cbg \u9762\u677F\u5B50\u8FDB\u7A0B\u7167\u5E38\u72EC\u7ACB\uFF09\u3002
# \u4EE3\u4EF7\uFF1A\u8FD0\u884C\u671F\u95F4\u63A7\u5236\u53F0\u88AB\u5360\u7528\uFF08\u540C gadget \u6A21\u5F0F\uFF09\uFF1B/exit \u9000\u51FA\u3002Ctrl+C \u4E0D\u627F\u8BFA\uFF1A
# RStudio \u63A7\u5236\u53F0\u5728 readline \u63D0\u793A\u7B26\u4E0B\u6309 Ctrl+C \u4E0D\u5411 R \u5C42\u629B\u4E2D\u65AD\u6761\u4EF6\uFF0C\u800C\u662F\u6E05\u7A7A
# \u5F53\u524D\u884C\u8FD4\u56DE\u7A7A\u4E32\uFF08\u4E0E\u7A7A\u56DE\u8F66\u65E0\u6CD5\u533A\u5206\uFF09\uFF1B\u771F\u7EC8\u7AEF\u91CC\u4E2D\u65AD\u6761\u4EF6\u80FD\u5192\u51FA\u6765\uFF0C\u5FAA\u73AF\u91CC\u4ECD
# \u4FDD\u7559\u6355\u83B7\u4F5C\u4E3A\u5C3D\u529B\u800C\u4E3A\u7684\u798F\u5229\uFF0C\u4F46\u4E0D\u5BF9\u7528\u6237\u5BA3\u4F20\u3002

# \u542F\u52A8\u6A2A\u5E45\uFF08ASCII \u5927\u5B57 + \u72B6\u6001\u884C\uFF09\u3002\u52A8\u753B\u53EA\u5728\u4EA4\u4E92\u5F0F\u4F1A\u8BDD\u64AD\u653E\uFF1B
# options(daiRH.cli_banner_speed = 0) \u53EF\u5173\u95ED\u5EF6\u8FDF\u3002
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
    "  \u2500\u2500 \u76F4\u63A5\u8F93\u5165\u4EFB\u52A1\u5F00\u59CB\u5BF9\u8BDD\uFF1B/help \u770B\u547D\u4EE4\uFF0C/exit \u9000\u51FA\n\n",
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

# /\u547D\u4EE4\uFF1A\u8FD4\u56DE "exit" \u8868\u793A\u9000\u51FA\u5FAA\u73AF\uFF0C"reset" \u8868\u793A\u91CD\u5EFA\u4F1A\u8BDD\uFF0C\u5176\u4F59\u4E3A\u5DF2\u5904\u7406\u3002
# /compact \u9700\u8981\u4F1A\u8BDD\u5BF9\u8C61\uFF08\u538B\u7F29\u6838\u5FC3\u4E0E\u9762\u677F\u5171\u7528 compact.R\uFF09\uFF1B
# agent/cfg \u5E26\u7F3A\u7701\u503C\uFF0C\u65E7\u7B7E\u540D\u8C03\u7528\u4E0E\u6D4B\u8BD5\u4E0D\u53D7\u5F71\u54CD\u3002
.dai_cli_command <- function(line, agent = NULL, cfg = dairh_config_get()) {
  parts <- strsplit(trimws(line), "[[:space:]]+")[[1]]
  cmd <- tolower(parts[[1]] %||% "")
  switch(cmd,
    "/exit" = , "/quit" = , "/q" = , "/bye" = "exit",
    "/clear" = , "/new" = "reset",
    "/compact" = {
      if (is.null(agent)) {
        cat("  \u4F1A\u8BDD\u4E0D\u53EF\u7528\uFF08\u521D\u59CB\u5316\u5931\u8D25\u6216\u5C1A\u672A\u542F\u52A8\uFF09\u3002\n")
      } else {
        # 0.8 \u8FDB\u5EA6\u63D0\u793A\uFF1A\u538B\u7F29\u662F\u4E00\u6B21\u6A21\u578B\u8BF7\u6C42\uFF0C\u53EF\u80FD\u9700\u8981\u51E0\u5341\u79D2
        cat("  \u6B63\u5728\u538B\u7F29\uFF08\u4E00\u6B21\u6A21\u578B\u8BF7\u6C42\uFF0C\u53EF\u80FD\u9700\u8981\u5341\u51E0\u79D2\u5230\u4E00\u5206\u949F\uFF09\u2026\u2026\n")
        utils::flush.console()
        res <- tryCatch(
          .dairh_compact_turns(agent, cfg),
          error = function(e) list(ok = FALSE, msg = conditionMessage(e))
        )
        if (isTRUE(res$ok)) {
          cat(sprintf(
            "  \u5DF2\u538B\u7F29\uFF1A\u539F\u5BF9\u8BDD %s \u8F6E \u2192 \u6458\u8981\uFF08%d \u5B57\uFF09\uFF1B\u786C\u9884\u7B97\u5DF2\u91CD\u7F6E\u3002\n",
            res$n_old, nchar(res$summary)
          ))
        } else {
          cat("  \u538B\u7F29\u5931\u8D25\uFF1A", res$msg, "\n", sep = "")
        }
      }
      "ok"
    },
    "/plan" = , "/build" = {
      # 0.7 \u6A21\u5F0F\u70ED\u5207\u6362\uFF1A\u4E0E\u9762\u677F\u5171\u7528 .dairh_set_mode\uFF08\u539F\u5730\u6362\u63D0\u793A\u8BCD+\u5DE5\u5177\u96C6\uFF0C\u5BF9\u8BDD\u4FDD\u7559\uFF09
      if (is.null(agent)) {
        cat("  \u4F1A\u8BDD\u4E0D\u53EF\u7528\uFF08\u521D\u59CB\u5316\u5931\u8D25\u6216\u5C1A\u672A\u542F\u52A8\uFF09\u3002\n")
      } else {
        mode <- if (identical(cmd, "/plan")) "plan" else "build"
        ok <- tryCatch({
          .dairh_set_mode(agent, mode, cfg)
          TRUE
        }, error = function(e) {
          cat("  \u6A21\u5F0F\u5207\u6362\u5931\u8D25\uFF1A", conditionMessage(e), "\n")
          FALSE
        })
        if (isTRUE(ok)) {
          cat(if (identical(mode, "plan"))
            "  \u5DF2\u5207\u6362\u5230\u8BA1\u5212\u6A21\u5F0F\uFF1A\u53EA\u8BFB\u8C03\u7814\uFF0C\u4EA4\u4ED8\u7ED3\u6784\u5316\u8BA1\u5212\uFF08\u5199/\u6267\u884C\u7C7B\u5DE5\u5177\u5DF2\u7269\u7406\u88C1\u526A\uFF09\u3002\n"
          else
            "  \u5DF2\u5207\u6362\u5230\u6784\u5EFA\u6A21\u5F0F\uFF1A\u5168\u5DE5\u5177\u6062\u590D\u3002\n")
        }
      }
      "ok"
    },
    "/tools" = {
      lt <- dairh_list_tools()
      # 0.7\uFF1A\u4F1A\u8BDD\u5728\u624B\u65F6\u6309\u5F53\u524D\u751F\u6548\u5DE5\u5177\u96C6\u6807\u6CE8\uFF08\u8BA1\u5212\u6A21\u5F0F\u7684\u7269\u7406\u88C1\u526A\u76F4\u89C2\u53EF\u89C1\uFF09
      active <- if (!is.null(agent)) {
        tryCatch(
          vapply(agent$get_tools(), function(t) as.character(t@name)[[1]], character(1)),
          error = function(e) NULL
        )
      } else NULL
      has_state <- !is.null(active)
      if (has_state) {
        cat(sprintf("  %-18s %-10s %-6s %s\n", "name", "source", "state", "description"))
      } else {
        cat(sprintf("  %-18s %-10s %s\n", "name", "source", "description"))
      }
      for (i in seq_len(nrow(lt))) {
        st <- if (!has_state) ""
        else if (lt$name[[i]] %in% active) "on" else "off"
        cat(sprintf("  %-18s %-10s %-6s %s\n",
          lt$name[[i]], lt$source[[i]], st,
          .dai_clip(lt$description[[i]] %||% "", if (has_state) 56 else 60)))
      }
      if (has_state) {
        cat("  (state=off: not registered in this session -- plan-mode trim or allow_* switches)\n")
      }
      "ok"
    },
    "/help" = {
      cat(
        "  /help            \u663E\u793A\u672C\u5E2E\u52A9\n",
        "  /clear           \u5F00\u65B0\u4F1A\u8BDD\uFF08\u6E05\u6A21\u578B\u5386\u53F2\uFF0C\u786C\u9884\u7B97\u5F52\u96F6\uFF09\n",
        "  /compact         \u538B\u7F29\u4E0A\u4E0B\u6587\uFF08\u6A21\u578B\u603B\u7ED3\u5F53\u524D\u4F1A\u8BDD\uFF0C\u91CD\u7F6E\u786C\u9884\u7B97\uFF09\n",
        "  /plan            \u5207\u6362\u5230\u8BA1\u5212\u6A21\u5F0F\uFF08\u53EA\u8BFB\u8C03\u7814\uFF0C\u5F53\u573A\u751F\u6548\uFF0C\u5BF9\u8BDD\u4FDD\u7559\uFF09\n",
        "  /build           \u5207\u6362\u5230\u6784\u5EFA\u6A21\u5F0F\uFF08\u5168\u5DE5\u5177\uFF0C\u5F53\u573A\u751F\u6548\uFF09\n",
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
#' \u63A7\u5236\u53F0\u6216\u7EC8\u7AEF\uFF09\uFF0C\u671F\u95F4\u63A7\u5236\u53F0\u88AB\u5360\u7528\uFF1B`/exit` \u9000\u51FA\u3002
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
    # interrupt \u6355\u83B7\u53EA\u5BF9\u771F\u7EC8\u7AEF\u751F\u6548\uFF08RStudio \u63A7\u5236\u53F0\u628A readline \u4E0B\u7684 Ctrl+C
    # \u53D8\u6210\u7A7A\u884C\uFF0C\u6761\u4EF6\u5230\u4E0D\u4E86 R \u5C42\uFF09\uFF1B\u5BF9\u5916\u53EA\u627F\u8BFA /exit\uFF0C\u89C1\u6587\u4EF6\u5934\u6CE8\u91CA\u3002
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
      act <- .dai_cli_command(line, agent = agent, cfg = cfg)
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
    # echo="output"\uFF08ellmer \u7528\u6237\u754C\u9762\u9ED8\u8BA4\u6863\uFF09\uFF1A\u6B63\u6587\u6D41\u5F0F\u65E0\u524D\u7F00\uFF0C\u5DE5\u5177\u8C03\u7528\u6E32\u67D3\u6210
    # "\u25CF [tool call] ..." + "\u23FA #> \u7ED3\u679C\u9884\u89C8"\uFF1Becho="all" \u4F1A\u7ED9\u6B63\u6587\u52A0 "< " \u524D\u7F00\u4E14\u66F4\u5435
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
