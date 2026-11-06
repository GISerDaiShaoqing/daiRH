# Subagent delegation (0.5): structural tests only -- no network access.
# All test source stays ASCII-only so parsing is locale-robust.

local_sub_trace_dir <- function() {
  withr::local_options(daiRH.trace_dir = file.path(tempdir(),
    paste0("dairh-trace-sub-", as.integer(Sys.time()), "-", Sys.getpid())),
    .local_envir = parent.frame())
}

test_that("subagent config defaults are sane", {
  cfg <- dairh_config_default()
  expect_true(isTRUE(cfg$allow_subagent))
  expect_identical(as.integer(cfg$subagent_max_steps), 8L)
})

test_that("delegate_task registration is gated by allow_subagent", {
  cfg <- dairh_config_default()
  cfg$allow_subagent <- FALSE
  tools_off <- dairh_agent_tools(cfg)
  expect_false("delegate_task" %in% names(tools_off))

  cfg$allow_subagent <- TRUE
  tools_on <- dairh_agent_tools(cfg)
  expect_true("delegate_task" %in% names(tools_on))
})

test_that("exclude filters delegate_task from the toolset", {
  local_sub_trace_dir()
  cfg <- dairh_config_default()
  tools <- dairh_agent_tools(cfg, exclude = "delegate_task")
  expect_false("delegate_task" %in% names(tools))
  expect_true("read_file" %in% names(tools))
  expect_true("show_plot" %in% names(tools))
})

test_that("subagent prompt is compact, self-contained and mentions sub-agent", {
  cfg <- dairh_config_default()
  p <- .dairh_subagent_prompt(cfg)
  expect_true(nchar(p) < nchar(dairh_system_prompt(cfg)))
  expect_match(p, "Sub-agent", fixed = TRUE)
  expect_match(p, dairh_base_dir(), fixed = TRUE)

  cfg2 <- cfg
  cfg2$restrict_paths <- FALSE
  expect_false(grepl("\u9650\u5236\u5728", .dairh_subagent_prompt(cfg2), fixed = TRUE))
})

test_that("delegate_task guards empty task and nested delegation", {
  local_sub_trace_dir()
  expect_match(
    .dairh_delegate_task("   ", cfg = dairh_config_default(), state = NULL),
    "FAIL", fixed = TRUE
  )
  st <- .dairh_new_state(dairh_config_default())
  st$tag <- "sub"
  expect_match(
    .dairh_delegate_task("x", cfg = dairh_config_default(), state = st),
    "\u4EC5\u652F\u6301\u4E00\u5C42", fixed = TRUE
  )
})

test_that("main agent state keeps tag main and trace carries agent field", {
  local_sub_trace_dir()
  st <- .dairh_new_state(dairh_config_default())
  expect_identical(st$tag, "main")

  nm <- "tt_agent_tag"
  dairh_register_tool(nm, function(x) paste0("OK: ", x), "tag echo",
    arguments = list(x = ellmer::type_string("x", required = TRUE)),
    overwrite = TRUE
  )
  withr::defer(dairh_unregister_tool(nm), envir = parent.frame())
  cfg <- dairh_config_default()
  tools <- dairh_agent_tools(cfg)
  invisible(tools[[nm]](x = "y"))

  p <- dairh_trace_path()
  lines <- readLines(p, warn = FALSE)
  j <- jsonlite::fromJSON(lines[length(lines)], simplifyVector = FALSE)
  expect_identical(j$agent, "main")
})
