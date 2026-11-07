# Plan/build mode (0.7): toolset gating, prompt variant, hot-swap core.
# All test source stays ASCII-only so parsing is locale-robust.

local_mode_trace_dir <- function() {
  withr::local_options(daiRH.trace_dir = file.path(tempdir(),
    paste0("dairh-trace-mode-", as.integer(Sys.time()), "-", Sys.getpid())),
    .local_envir = parent.frame())
}

test_that("plan mode drops exactly write/run/deliver tools and keeps read-only set", {
  local_mode_trace_dir()
  cfg <- dairh_config_default()
  tools_build <- dairh_agent_tools(cfg)
  expect_true(all(c("create_file", "edit_file", "run_r_code", "show_plot",
    "show_html") %in% names(tools_build)))

  cfg$mode <- "plan"
  tools_plan <- dairh_agent_tools(cfg)
  for (nm in c("create_file", "edit_file", "run_r_code", "show_plot", "show_html")) {
    expect_false(nm %in% names(tools_plan), info = paste("plan mode drops", nm))
  }
  for (nm in c("read_file", "list_files", "get_r_help", "workspace_summary",
      "get_editor_context", "read_skill", "delegate_task")) {
    expect_true(nm %in% names(tools_plan), info = paste("plan mode keeps", nm))
  }
})

test_that("plan mode does not resurrect tools disabled by allow_edit/allow_run", {
  local_mode_trace_dir()
  cfg <- dairh_config_default()
  cfg$mode <- "plan"
  cfg$allow_edit <- FALSE
  cfg$allow_run <- FALSE
  tools <- dairh_agent_tools(cfg)
  expect_false("edit_file" %in% names(tools))
  expect_false("run_r_code" %in% names(tools))
  expect_true("read_file" %in% names(tools))
})

test_that("plan prompt differs from build prompt and carries plan markers", {
  cfg <- dairh_config_default()
  p_build <- dairh_system_prompt(cfg)
  cfg$mode <- "plan"
  p_plan <- dairh_system_prompt(cfg)
  expect_false(identical(p_build, p_plan))
  expect_match(p_plan, "plan mode", fixed = TRUE)
  expect_match(p_plan, "\u8ba1\u5212\u6a21\u5f0f\u89c4\u5219", fixed = TRUE)  # plan rules header
  expect_match(p_plan, "\u7ed3\u6784\u5316\u8ba1\u5212", fixed = TRUE)         # structured plan
  expect_false(grepl("\u8ba1\u5212\u6a21\u5f0f\u89c4\u5219", p_build, fixed = TRUE))
})

test_that(".dairh_set_mode hot-swaps prompt and tools on a fake client", {
  local_mode_trace_dir()
  st <- .dairh_new_state(dairh_config_default())
  st$n_calls <- 3L # budget continuity probe: the SAME state env must be reused
  holder <- new.env(parent = emptyenv())
  fake <- list(
    set_system_prompt = function(p) holder$prompt <- p,
    set_tools = function(t) holder$tools <- t
  )
  attr(fake, ".dairh_state") <- st
  cfg <- dairh_config_default()

  invisible(.dairh_set_mode(fake, "plan", cfg))
  expect_match(holder$prompt, "plan mode", fixed = TRUE)
  tnames <- vapply(holder$tools, function(t) as.character(t@name), character(1))
  expect_false("create_file" %in% tnames)
  expect_true("read_file" %in% tnames)
  expect_identical(st$mode, "plan")
  expect_identical(st$n_calls, 3L)

  # trace event type=mode carrying the new mode value
  p <- dairh_trace_path()
  lines <- readLines(p, warn = FALSE)
  j <- jsonlite::fromJSON(lines[length(lines)], simplifyVector = FALSE)
  expect_identical(j$type, "mode")
  expect_identical(j$mode, "plan")

  # switching back restores the full build toolset
  invisible(.dairh_set_mode(fake, "build", cfg))
  tnames2 <- vapply(holder$tools, function(t) as.character(t@name), character(1))
  expect_true("create_file" %in% tnames2)
  expect_identical(st$mode, "build")
})

test_that(".dairh_set_mode normalizes junk mode values to build", {
  local_mode_trace_dir()
  st <- .dairh_new_state(dairh_config_default())
  fake <- list(
    set_system_prompt = function(p) NULL,
    set_tools = function(t) NULL
  )
  attr(fake, ".dairh_state") <- st
  invisible(.dairh_set_mode(fake, "JUNK", dairh_config_default()))
  expect_identical(st$mode, "build")
})

test_that(".dairh_set_mode rejects a client without .dairh_state", {
  fake <- list(
    set_system_prompt = function(p) NULL,
    set_tools = function(t) NULL
  )
  expect_error(.dairh_set_mode(fake, "plan"), "dairh_new_agent")
})
