# DaiRH harness \u5C42\u6D4B\u8BD5\uFF1A\u6CE8\u518C\u8868 / \u94A9\u5B50 / \u786C\u9884\u7B97 / trace / tools_profile
# \u6CE8\u610F\uFF1A\u6CE8\u518C\u8868\u662F\u8FDB\u7A0B\u7EA7\u5168\u5C40\u7684\uFF0C\u6BCF\u4E2A\u6D4B\u8BD5\u90FD\u8981\u6E05\u7406\u81EA\u5DF1\u6CE8\u518C\u7684\u4E1C\u897F\u3002

reg_and_clean <- function(...) {
  nm <- dairh_register_tool(...)
  withr::defer(dairh_unregister_tool(nm), envir = parent.frame())
  nm
}

# \u6D4B\u8BD5\u671F\u95F4 trace \u5199\u4E34\u65F6\u76EE\u5F55\uFF0C\u4E0D\u6C61\u67D3\u7528\u6237\u771F\u5B9E trace \u76EE\u5F55
local_test_trace_dir <- function() {
  withr::local_options(daiRH.trace_dir = file.path(tempdir(), "dairh-test-traces"))
  invisible(NULL)
}

local_test_trace_dir()
test_that("dairh_register_tool: register, list, unregister, conflicts", {
  nm <- reg_and_clean(
    "tt_echo", function(text) paste0("OK: ", toupper(text)),
    "Uppercase the text.",
    arguments = list(text = ellmer::type_string("t", required = TRUE))
  )
  lt <- dairh_list_tools()
  expect_true(nm %in% lt$name)
  expect_true("custom" %in% lt$source)

  # \u540C\u540D\u91CD\u590D\u6CE8\u518C\u62A5\u9519\uFF0Coverwrite=TRUE \u624D\u653E\u884C
  # \uFF08ASCII \u5B50\u4E32\u5339\u914D\uFF1A\u672C\u673A ASCII locale \u4E0B\u5BF9\u4E2D\u6587\u62A5\u9519\u4FE1\u606F\u505A regexp \u4F1A\u629B\u7F16\u7801\u9519\uFF09
  expect_error(
    dairh_register_tool(nm, function(text) "x", "d",
      arguments = list(text = ellmer::type_string("t"))),
    "overwrite = TRUE", fixed = TRUE
  )
  expect_error(
    dairh_register_tool("read_file", function(path) "x", "d",
      arguments = list(path = ellmer::type_string("p"))),
    "overwrite = TRUE", fixed = TRUE
  )
  expect_error(
    dairh_register_tool("bad name!", function() "x", "d"),
    "64", fixed = TRUE
  )
  # \u5F62\u53C2\u4E0E arguments \u4E0D\u5339\u914D\u5728\u6CE8\u518C\u65F6\u5C31\u62A5\u9519\uFF08\u5FEB\u901F\u5931\u8D25\uFF09
  expect_error(
    dairh_register_tool("tt_mismatch", function(path) "x", "d", arguments = list()),
    "path", fixed = TRUE
  )

  expect_true(dairh_unregister_tool(nm))
  expect_false(dairh_unregister_tool(nm))
})

local_test_trace_dir()
test_that("dairh_agent_tools: custom tools merged, real names (not tool_001)", {
  nm <- reg_and_clean(
    "tt_echo", function(text) paste0("OK: ", toupper(text)),
    "Uppercase the text.",
    arguments = list(text = ellmer::type_string("t", required = TRUE))
  )
  cfg <- dairh_config_default()
  tools <- dairh_agent_tools(cfg)
  expect_true(all(c("read_file", "get_r_help", nm) %in% names(tools)))
  # \u5173\u952E\u56DE\u5F52\uFF1A\u66FE\u7ECF\u533F\u540D\u51FD\u6570\u88AB ellmer \u547D\u540D\u6210 tool_001..008
  expect_identical(tools[["read_file"]]@name, "read_file")
  expect_identical(tools[[nm]]@name, nm)
  # \u7ED3\u679C\u9644\u5E26 state
  expect_true(is.environment(attr(tools, ".dairh_state")))
  # \u5305\u88C5\u5668\u53EF\u76F4\u63A5\u8C03\u7528
  expect_identical(tools[[nm]](text = "abc"), "OK: ABC")
})

local_test_trace_dir()
test_that("hard budget: max_steps blocks excess calls within one turn", {
  nm <- reg_and_clean(
    "tt_echo", function(text) paste0("OK: ", text), "echo",
    arguments = list(text = ellmer::type_string("t", required = TRUE)),
    overwrite = TRUE
  )
  cfg <- dairh_config_default()
  cfg$max_steps <- 2
  tools <- dairh_agent_tools(cfg)
  r1 <- tools[[nm]](text = "a")
  r2 <- tools[[nm]](text = "b")
  r3 <- tools[[nm]](text = "c")
  expect_identical(r1, "OK: a")
  expect_identical(r2, "OK: b")
  expect_match(r3, "FAIL")
  expect_match(r3, "\u786C\u9884\u7B97", fixed = TRUE)
})

local_test_trace_dir()
test_that("turn reset: new user turn restores budget (mock client)", {
  nm <- reg_and_clean(
    "tt_echo", function(text) paste0("OK: ", text), "echo",
    arguments = list(text = ellmer::type_string("t", required = TRUE)),
    overwrite = TRUE
  )
  cfg <- dairh_config_default()
  cfg$max_steps <- 2
  state <- .dairh_new_state(cfg)
  tools <- dairh_agent_tools(cfg, state = state)
  # \u7528\u76D2\u5B50\u73AF\u5883\u5B58\u56DE\u5408\u5217\u8868\uFF08\u907F\u5F00 <<- \u7684\u4F5C\u7528\u57DF\u5751\uFF09
  box <- new.env(parent = emptyenv())
  box$turns <- list()
  state$client <- list(get_turns = function(include_system_prompt = FALSE) box$turns)
  Turn <- getFromNamespace("Turn", "ellmer")

  # \u5148\u7ED1\u5B9A\u7ED3\u679C\u518D\u65AD\u8A00\uFF1A\u672C\u673A\u7684 testthat expect_match \u4F1A\u53CC\u91CD\u6C42\u503C\u53C2\u6570\uFF0C
  # \u5185\u8054\u8C03\u7528\u4F1A\u8BA9\u9884\u7B97\u8BA1\u6570\u7FFB\u500D
  r1 <- tools[[nm]](text = "t1")
  r2 <- tools[[nm]](text = "t2")
  r3 <- tools[[nm]](text = "t3")
  expect_match(r1, "^OK")
  expect_match(r2, "^OK")
  expect_match(r3, "FAIL")

  # \u65B0\u7684 user \u56DE\u5408 \u2192 \u9884\u7B97\u91CD\u7F6E
  box$turns <- list(Turn("user", "hi"), Turn("assistant", "yo"), Turn("user", "go"))
  r4 <- tools[[nm]](text = "t4")
  r5 <- tools[[nm]](text = "t5")
  r6 <- tools[[nm]](text = "t6")
  expect_match(r4, "^OK")
  expect_match(r5, "^OK")
  expect_match(r6, "FAIL")

  # assistant \u56DE\u5408\u4E0D\u91CD\u7F6E
  box$turns <- c(box$turns, list(Turn("assistant", "x")))
  r7 <- tools[[nm]](text = "t7")
  expect_match(r7, "FAIL")

  # \u518D\u6765\u4E00\u8F6E user \u2192 \u518D\u6B21\u91CD\u7F6E
  box$turns <- c(box$turns, list(Turn("user", "again")))
  r8 <- tools[[nm]](text = "t8")
  expect_match(r8, "^OK")
})

test_that("tool-result turns (role=user, empty text) must NOT reset budget", {
  # \u5B9E\u6D4B\uFF08\u5047\u670D\u52A1\u5668\u7AEF\u5230\u7AEF\uFF09\uFF1Aellmer \u628A\u5DE5\u5177\u7ED3\u679C\u5B58\u6210 role="user" \u4E14 @text \u4E3A\u7A7A\u7684\u56DE\u5408\u3002
  # \u65E7\u7248\u672C\u53EA\u6570 user \u56DE\u5408\u6570\uFF0C\u5BFC\u81F4\u6BCF\u6B21\u5DE5\u5177\u8C03\u7528\u540E\u9884\u7B97\u90FD\u88AB\u8BEF\u91CD\u7F6E\uFF08\u6C38\u4E0D\u62E6\u622A\uFF09\u3002
  nm <- reg_and_clean(
    "tt_echo", function(text) paste0("OK: ", text), "echo",
    arguments = list(text = ellmer::type_string("t", required = TRUE)),
    overwrite = TRUE
  )
  cfg <- dairh_config_default()
  cfg$max_steps <- 2
  state <- .dairh_new_state(cfg)
  tools <- dairh_agent_tools(cfg, state = state)
  box <- new.env(parent = emptyenv())
  box$turns <- list()
  state$client <- list(get_turns = function(include_system_prompt = FALSE) box$turns)
  Turn <- getFromNamespace("Turn", "ellmer")

  # \u771F\u5B9E\u5F62\u6001\uFF1A\u7528\u6237\u6D88\u606F\u4E0E\u5DE5\u5177\u7ED3\u679C\u56DE\u5408\uFF08role=user\u3001text \u7A7A\uFF09\u4EA4\u66FF
  box$turns <- list(
    Turn("user", "task message"),
    Turn("assistant", ""),
    Turn("user", "")
  )
  r1 <- tools[[nm]](text = "a")   # \u53EA\u6709 1 \u4E2A\u771F\u7528\u6237\u56DE\u5408\uFF0C\u4E0D\u91CD\u7F6E
  r2 <- tools[[nm]](text = "b")   # \u7B2C 2 \u6B21\uFF0C\u9884\u7B97\u5185
  r3 <- tools[[nm]](text = "c")   # \u7B2C 3 \u6B21\uFF0C\u5FC5\u987B\u88AB\u62E6
  expect_match(r1, "^OK")
  expect_match(r2, "^OK")
  expect_match(r3, "FAIL")
})

test_that("trace roundtrip survives Chinese content under ASCII locale", {
  nm <- reg_and_clean(
    "tt_cn", function(text) paste0("OK: \u7ED3\u679C-", text), "echo chinese",
    arguments = list(text = ellmer::type_string("t", required = TRUE)),
    overwrite = TRUE
  )
  withr::local_options(daiRH.trace_dir = file.path(tempdir(), paste0(
    "dairh-trace-cn-", as.integer(Sys.time())
  )))
  cfg <- dairh_config_default()
  cfg$max_steps <- 50
  tools <- dairh_agent_tools(cfg)
  res <- tools[[nm]](text = "\u4E2D\u6587\u53C2\u6570")
  expect_match(res, "^OK")
  df <- dairh_trace(n = 3)
  expect_s3_class(df, "data.frame")
  expect_true(nrow(df) >= 1L)
  hit <- df[df$tool == nm, ]
  expect_true(nrow(hit) >= 1L)
  # \u4ECE jsonl \u8BFB\u56DE\u7684\u7ED3\u679C\u91CC\u80FD\u627E\u56DE\u4E2D\u6587\uFF08\u8BFB\u53D6\u5668\u7F16\u7801\u4FEE\u590D\u7684\u56DE\u5F52\uFF09
  expect_true(grepl("\u4E2D\u6587", hit$result[[nrow(hit)]], fixed = TRUE))
})

local_test_trace_dir()
test_that("hooks: pre_tool veto and post_tool rewrite", {
  nm <- reg_and_clean(
    "tt_echo", function(text) paste0("OK: ", text), "echo",
    arguments = list(text = ellmer::type_string("t", required = TRUE)),
    overwrite = TRUE
  )
  cfg <- dairh_config_default()
  cfg$max_steps <- 50

  remover <- dairh_add_hook("pre_tool", function(name, args) {
    if (identical(args$text, "secret")) "blocked-word"
  })
  tools <- dairh_agent_tools(cfg)
  rv <- tools[[nm]](text = "secret")
  expect_match(rv, "FAIL")
  expect_match(rv, "\u94A9\u5B50\u62E6\u622A", fixed = TRUE)
  # \u94A9\u5B50\u653E\u884C\u65F6\u7ED3\u679C\u4E0D\u53D8
  expect_match(tools[[nm]](text = "fine"), "^OK")
  remover()
  expect_false(dairh_remove_hook("pre_tool", "hook1"))

  dairh_add_hook("post_tool", function(name, args, result) paste0(result, " [post]"))
  tools2 <- dairh_agent_tools(cfg)
  expect_match(tools2[[nm]](text = "d"), "[post]", fixed = TRUE)
  expect_true(dairh_remove_hook("post_tool", "hook1"))
  tools3 <- dairh_agent_tools(cfg)
  expect_false(grepl("[post]", tools3[[nm]](text = "d"), fixed = TRUE))

  # \u94A9\u5B50\u7B7E\u540D\u4E0D\u5BF9\u65F6\u62A5\u9519\uFF08ASCII \u5B50\u4E32\u5339\u914D\uFF09
  expect_error(dairh_add_hook("pre_tool", function(name) NULL), "pre_tool", fixed = TRUE)
})

test_that("trace: jsonl written and readable", {
  nm <- reg_and_clean(
    "tt_echo", function(text) paste0("OK: ", text), "echo",
    arguments = list(text = ellmer::type_string("t", required = TRUE)),
    overwrite = TRUE
  )
  tmpd <- file.path(tempdir(), paste0("dairh-trace-", as.integer(Sys.time())))
  withr::local_options(daiRH.trace_dir = tmpd)
  cfg <- dairh_config_default()
  cfg$max_steps <- 50
  tools <- dairh_agent_tools(cfg)
  p0 <- dairh_trace_path()
  invisible(tools[[nm]](text = "x"))
  p <- dairh_trace_path()
  expect_false(is.null(p))
  expect_true(file.exists(p))
  lines <- readLines(p, warn = FALSE)
  lines <- lines[nzchar(lines)]
  expect_true(length(lines) >= 1L)
  j <- jsonlite::fromJSON(lines[[length(lines)]], simplifyVector = FALSE)
  expect_identical(j$type, "tool")
  expect_identical(j$tool, nm)
  expect_true(isTRUE(j$ok))

  df <- dairh_trace(n = 5)
  expect_s3_class(df, "data.frame")
  expect_true(all(c("type", "tool", "ok", "result") %in% names(df)))
  # \u5173\u95ED trace \u540E\u4E0D\u518D\u5199
  cfg2 <- cfg
  cfg2$trace <- FALSE
  tools2 <- dairh_agent_tools(cfg2)
  before <- file.info(p)$size
  invisible(tools2[[nm]](text = "y"))
  expect_identical(file.info(p)$size, before)
})

local_test_trace_dir()
test_that("overwrite builtin then unregister restores builtin", {
  nm <- reg_and_clean(
    "read_file", function(path) "OK: custom read", "replaced",
    arguments = list(path = ellmer::type_string("p", required = TRUE)),
    overwrite = TRUE
  )
  cfg <- dairh_config_default()
  t1 <- dairh_agent_tools(cfg)
  expect_match(t1[["read_file"]](path = "zz"), "custom read")
  dairh_unregister_tool("read_file")
  t2 <- dairh_agent_tools(cfg)
  expect_match(t2[["read_file"]](path = "definitely-not-here-123"), "FAIL")
})

local_test_trace_dir()
test_that("tools_profile sourced once per mtime", {
  tmpd <- file.path(tempdir(), paste0("dairh-prof-", as.integer(Sys.time())))
  dir.create(tmpd, recursive = TRUE)
  withr::defer(unlink(tmpd, recursive = TRUE), envir = parent.frame())
  pf <- file.path(tmpd, "profile.R")
  writeLines(c(
    "dairh_register_tool(\"tt_profile_tool\", function() \"OK: from profile\",",
    "  \"tool from profile\", overwrite = TRUE)"
  ), pf)
  cfg <- dairh_config_default()
  cfg$tools_profile <- pf
  expect_true(.dairh_source_profile(cfg))
  tools <- dairh_agent_tools(cfg)
  expect_true("tt_profile_tool" %in% names(tools))
  expect_identical(tools[["tt_profile_tool"]](), "OK: from profile")
  # \u540C\u4E00\u6587\u4EF6\u4E8C\u6B21 source \u662F no-op\uFF08mtime \u53BB\u91CD\uFF09\uFF0C\u4E0D\u4F1A\u56E0 overwrite \u62A5\u9519
  expect_true(.dairh_source_profile(cfg))
  dairh_unregister_tool("tt_profile_tool")
  # \u4E0D\u5B58\u5728\u7684\u6587\u4EF6 \u2192 warning + FALSE
  cfg$tools_profile <- file.path(tmpd, "nope.R")
  expect_warning(expect_false(.dairh_source_profile(cfg)))
})

test_that("config defaults carry trace / tools_profile and roundtrip", {
  tmpcfg <- file.path(tempdir(), paste0("dairh-cfg-", as.integer(Sys.time())), "config.json")
  dir.create(dirname(tmpcfg), recursive = TRUE, showWarnings = FALSE)
  withr::local_options(daiRH.config_path = tmpcfg)
  d <- dairh_config_default()
  expect_true(isTRUE(d$trace))
  expect_identical(d$tools_profile, "")
  dairh_config_set(trace = FALSE, tools_profile = "C:/tmp/profile.R")
  cfg <- dairh_config_get()
  expect_false(isTRUE(cfg$trace))
  expect_identical(cfg$tools_profile, "C:/tmp/profile.R")
  unlink(dirname(tmpcfg), recursive = TRUE)
})

local_test_trace_dir()
test_that("agent tools respect allow_edit/allow_run with harness wrapping", {
  nm <- reg_and_clean(
    "tt_echo", function(text) paste0("OK: ", text), "echo",
    arguments = list(text = ellmer::type_string("t", required = TRUE))
  )
  cfg <- dairh_config_default()
  cfg$allow_edit <- FALSE
  cfg$allow_run <- FALSE
  tools <- dairh_agent_tools(cfg)
  expect_false("edit_file" %in% names(tools))
  expect_false("create_file" %in% names(tools))
  expect_false("run_r_code" %in% names(tools))
  expect_true(all(c("read_file", "list_files", nm) %in% names(tools)))
})

local_test_trace_dir()
test_that("dairh_new_agent attaches state and hard-budget wraps (regression for clear button)", {
  nm <- reg_and_clean(
    "tt_echo2", function(text) paste0("OK: ", text), "echo",
    arguments = list(text = ellmer::type_string("t", required = TRUE)),
    overwrite = TRUE
  )
  cfg <- dairh_config_default()
  cfg$max_steps <- 2
  ag <- dairh_new_agent(cfg)
  st <- attr(ag, ".dairh_state")
  expect_true(is.environment(st))
  expect_identical(st$n_calls, 0L)
  expect_true(is.na(st$last_user_n))
  expect_identical(st$budget, 2L)
})

local_test_trace_dir()
test_that("panel clear: .dai_reset_agent_state zeroes budget, empties turns, logs session_reset", {
  nm <- reg_and_clean(
    "tt_echo3", function(text) paste0("OK: ", text), "echo",
    arguments = list(text = ellmer::type_string("t", required = TRUE)),
    overwrite = TRUE
  )
  cfg <- dairh_config_default()
  cfg$max_steps <- 2
  state <- .dairh_new_state(cfg)
  tools <- dairh_agent_tools(cfg, state = state)
  # \u76D2\u5B50\u5B58 set_turns \u89C2\u6D4B\uFF08\u907F\u5F00 <<<- \u4F5C\u7528\u57DF\u5751\uFF09
  box <- new.env(parent = emptyenv())
  box$nturns <- -1L
  fake_client <- list(set_turns = function(v) {
    box$nturns <- length(v)
    invisible(NULL)
  })
  attr(fake_client, ".dairh_state") <- state

  r1 <- tools[[nm]](text = "a")
  r2 <- tools[[nm]](text = "b")
  r3 <- tools[[nm]](text = "c")
  expect_match(r1, "^OK")
  expect_match(r2, "^OK")
  expect_match(r3, "FAIL")

  daiRH:::.dai_reset_agent_state(fake_client)
  expect_identical(state$n_calls, 0L)
  expect_true(is.na(state$last_user_n))
  expect_identical(box$nturns, 0L)
  r4 <- tools[[nm]](text = "d")
  expect_match(r4, "^OK")

  df <- dairh_trace(8)
  expect_true(any(df$type == "session_reset"))
})

local_test_trace_dir()
test_that("orphan sweep: callr-fingerprinted child killed; self pid only de-registered", {
  tmpd <- file.path(tempdir(), paste0("dairh-pids-", as.integer(Sys.time())))
  dir.create(tmpd, recursive = TRUE, showWarnings = FALSE)
  withr::defer(unlink(tmpd, recursive = TRUE), envir = parent.frame())
  withr::local_options(daiRH.pid_dir = tmpd)

  # 1) \u771F callr \u5B50\u8FDB\u7A0B\uFF08cmdline \u5E26 callr-scr- \u4E34\u65F6\u811A\u672C\uFF09\u2192 \u6307\u7EB9\u547D\u4E2D \u2192 \u56DE\u6536
  ch <- callr::r_bg(function() Sys.sleep(60), stdout = tempfile(), stderr = tempfile())
  pf <- file.path(tmpd, "x1.pid")
  writeLines(as.character(ch$get_pid()), pf)
  k <- .dairh_sweep_orphan_children()
  expect_identical(k, 1L)
  Sys.sleep(0.5)
  expect_false(isTRUE(tryCatch(ch$is_alive(), error = function(e) FALSE)))
  expect_false(file.exists(pf))

  # 2) \u6307\u7EB9\u4E0D\u5339\u914D\uFF08\u672C\u6D4B\u8BD5\u8FDB\u7A0B\uFF0Ccmdline \u65E0 callr-scr-\uFF09\u2192 \u7EDD\u4E0D\u6740\uFF0C\u53EA\u6E05\u767B\u8BB0
  own <- as.integer(Sys.getpid())
  pf2 <- file.path(tmpd, "x2.pid")
  writeLines(as.character(own), pf2)
  k <- .dairh_sweep_orphan_children()
  expect_identical(k, 0L)
  expect_false(file.exists(pf2))

  # 3) skip_pids \u547D\u4E2D \u2192 \u767B\u8BB0\u4FDD\u7559
  pf3 <- file.path(tmpd, "x3.pid")
  writeLines(as.character(own), pf3)
  k <- .dairh_sweep_orphan_children(skip_pids = own)
  expect_identical(k, 0L)
  expect_true(file.exists(pf3))
  unlink(pf3)

  # 4) \u5783\u573E\u8BB0\u5F55 \u2192 \u76F4\u63A5\u6E05\uFF0C\u4E0D\u56DE\u6536\u4EFB\u4F55\u4E1C\u897F
  pf4 <- file.path(tmpd, "x4.pid")
  writeLines("not-a-pid", pf4)
  k <- .dairh_sweep_orphan_children()
  expect_identical(k, 0L)
  expect_false(file.exists(pf4))

  # 5) \u8D85\u8FC7 1 \u5929\u7684\u8FC7\u671F\u767B\u8BB0 \u2192 \u8FC7\u671F\u6E05\u7406
  pf5 <- file.path(tmpd, "x5.pid")
  writeLines("1234", pf5)
  Sys.setFileTime(pf5, Sys.time() - 86400 * 2)
  k <- .dairh_sweep_orphan_children()
  expect_identical(k, 0L)
  expect_false(file.exists(pf5))

  # 6) \u6838\u4E0D\u4E86\u6307\u7EB9\u7684 pid\uFF08\u5982\u53D7\u4FDD\u62A4\u8FDB\u7A0B\uFF09\u2192 \u7B2C\u4E00\u6B21\u8D34 .stale\uFF0C\u7B2C\u4E8C\u6B21\u6E05\u6389\uFF0C\u7EDD\u4E0D\u52A8\u5200
  pf6 <- file.path(tmpd, "x6.pid")
  writeLines("4", pf6)
  k <- .dairh_sweep_orphan_children()
  if (file.exists(paste0(pf6, ".stale"))) {
    expect_false(file.exists(pf6))
    k <- .dairh_sweep_orphan_children()
    expect_false(file.exists(paste0(pf6, ".stale")))
  } else {
    expect_false(file.exists(pf6))
  }
})

local_test_trace_dir()
test_that("show_plot prep: guards path/ext/size and returns absolute path", {
  tmpd <- file.path(tempdir(), paste0("dairh-plot-", as.integer(Sys.time())))
  dir.create(tmpd, recursive = TRUE, showWarnings = FALSE)
  withr::defer(unlink(tmpd, recursive = TRUE), envir = parent.frame())

  ok_png <- file.path(tmpd, "ok.png")
  con <- file(ok_png, open = "wb")
  writeBin(as.raw(c(0x89, 0x50, 0x4E, 0x47, 1:8)), con)
  close(con)

  r <- .dai_show_plot_prep("nope.png", base = tmpd, restrict = TRUE)
  expect_false(r$ok)
  expect_match(r$msg, "FAIL", fixed = TRUE)

  bad <- file.path(tmpd, "x.txt")
  writeLines("hi", bad)
  r <- .dai_show_plot_prep(bad, base = tmpd, restrict = TRUE)
  expect_false(r$ok)
  expect_match(r$msg, "png/jpg", fixed = TRUE)

  r <- .dai_show_plot_prep("ok.png", base = tmpd, restrict = TRUE)
  expect_true(r$ok)
  expect_identical(r$msg, normalizePath(ok_png, winslash = "/"))

  outside <- tempfile(fileext = ".png")
  con <- file(outside, open = "wb")
  writeBin(as.raw(1:4), con)
  close(con)
  withr::defer(unlink(outside), envir = parent.frame())
  r <- .dai_show_plot_prep(outside, base = tmpd, restrict = TRUE)
  expect_false(r$ok)
  expect_match(r$msg, "FAIL", fixed = TRUE)
  r <- .dai_show_plot_prep(outside, base = tmpd, restrict = FALSE)
  expect_true(r$ok)
})

local_test_trace_dir()
test_that("show_plot tool returns Content list (text + inline image) on success", {
  tmpd <- file.path(tempdir(), paste0("dairh-plot2-", as.integer(Sys.time())))
  dir.create(tmpd, recursive = TRUE, showWarnings = FALSE)
  withr::defer(unlink(tmpd, recursive = TRUE), envir = parent.frame())
  # \u5DE5\u5177\u7684 base = dairh_base_dir() = getwd()\uFF08\u65E0\u5934\u73AF\u5883\uFF09\uFF1B\u5207\u8FDB tmpd \u624D\u8FC7\u8DEF\u5F84\u95F8
  withr::local_dir(tmpd)

  # content_image_file \u4F1A\u771F\u5B9E\u8BFB\u53D6\u5E76 base64\uFF0C\u9700\u8981\u771F PNG\uFF08prep \u6D4B\u8BD5\u7684\u5047\u5B57\u8282\u591F\u7528\uFF0C\u8FD9\u91CC\u4E0D\u591F\uFF09
  ok_png <- file.path(tmpd, "ok.png")
  grDevices::png(ok_png, width = 400, height = 400)
  graphics::plot(1:3)
  grDevices::dev.off()

  tools <- dairh_agent_tools(
    dairh_config_default(), state = .dairh_new_state(dairh_config_default())
  )
  expect_true("show_plot" %in% names(tools))

  # FAIL path: plain character, unchanged
  bad <- file.path(tmpd, "x.txt")
  writeLines("hi", bad)
  out_fail <- tools$show_plot(path = bad)
  expect_true(is.character(out_fail))
  expect_match(out_fail, "png/jpg", fixed = TRUE)

  # OK path: list of Content (text first, image second)
  out_ok <- tools$show_plot(path = ok_png)
  expect_true(is.list(out_ok))
  expect_length(out_ok, 2L)
  expect_true(all(vapply(out_ok, inherits, logical(1), "ellmer::Content")))
  expect_match(out_ok[[1]]@text, "OK", fixed = TRUE)
  expect_s3_class(out_ok[[2]], "ellmer::ContentImageInline")
})

local_test_trace_dir()
test_that("show_html: validates path/ext/size, opens via bridge or browser", {
  tmpd <- file.path(tempdir(), paste0("dairh-html-", as.integer(Sys.time())))
  dir.create(tmpd, recursive = TRUE, showWarnings = FALSE)
  withr::defer(unlink(tmpd, recursive = TRUE), envir = parent.frame())

  expect_match(.dai_show_html("nope.html", base = tmpd, restrict = TRUE),
    "FAIL", fixed = TRUE)
  txt <- file.path(tmpd, "x.txt")
  writeLines("hi", txt)
  expect_match(.dai_show_html(txt, base = tmpd, restrict = TRUE),
    "html/htm", fixed = TRUE)

  ok <- file.path(tmpd, "map.html")
  writeLines("<html><body>leaflet</body></html>", ok)

  # no bridge configured -> browseURL fallback (mocked, nothing really opens)
  withr::local_options(daiRH.bridge_dir = NULL)
  local_mocked_bindings(browseURL = function(...) invisible(NULL),
    .package = "utils")
  out <- .dai_show_html(ok, base = tmpd, restrict = TRUE)
  expect_match(out, "OK", fixed = TRUE)
})

local_test_trace_dir()
test_that("bridge viewer op: opens existing file, errors on missing", {
  called <- new.env(parent = emptyenv())
  called$path <- NULL
  local_mocked_bindings(
    .dairh_open_viewer = function(url) {
      called$path <- url
      TRUE
    }
  )
  f <- tempfile(fileext = ".html")
  writeLines("<html></html>", f)
  withr::defer(unlink(f), envir = parent.frame())
  expect_identical(.dairh_bridge_exec("viewer", list(path = f)), "ok")
  expect_identical(called$path, f)
  expect_error(.dairh_bridge_exec("viewer", list(path = "")), "viewer", fixed = TRUE)
})

local_test_trace_dir()
test_that("cli: banner runs headless and command router routes", {
  withr::local_options(daiRH.cli_banner_speed = 0)
  cfg <- dairh_config_default()
  expect_invisible(.dai_banner(cfg))
  expect_identical(.dai_cli_command("/exit"), "exit")
  expect_identical(.dai_cli_command("/quit"), "exit")
  expect_identical(.dai_cli_command("/clear"), "reset")
  expect_identical(.dai_cli_command("/new"), "reset")
  expect_identical(.dai_cli_command("/tools"), "ok")
  expect_identical(.dai_cli_command("/help"), "ok")
  expect_identical(.dai_cli_command("/nope"), "ok")
})
