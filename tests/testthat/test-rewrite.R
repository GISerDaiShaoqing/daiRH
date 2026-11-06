# Hook argument rewriting (0.5): pre_tool hooks may return dairh_rewrite_args().
# All test source stays ASCII-only so parsing is locale-robust.

local_rw_trace_dir <- function() {
  withr::local_options(daiRH.trace_dir = file.path(tempdir(),
    paste0("dairh-trace-rw-", as.integer(Sys.time()), "-", Sys.getpid())),
    .local_envir = parent.frame())
}

reg_rw_tool <- function(name, fn) {
  dairh_register_tool(name, fn, "echo for rewrite tests",
    arguments = list(x = ellmer::type_string("x", required = TRUE)),
    overwrite = TRUE
  )
  withr::defer(dairh_unregister_tool(name), envir = parent.frame())
  name
}

test_that("dairh_rewrite_args validates input", {
  # message starts with ASCII "args " in both encodings the parser may produce
  # (real UTF-8 on UTF-8 locales, <U+XXXX> placeholders under C locale), so we
  # anchor on that instead of matching Chinese text.
  expect_error(dairh_rewrite_args("not-a-list"), "^args")
  expect_error(dairh_rewrite_args(list("unnamed")), "^args")
  rw <- dairh_rewrite_args(list(x = 1))
  expect_s3_class(rw, "dairh_hook_rewrite")
})

test_that("pre_tool hook can rewrite tool arguments", {
  local_rw_trace_dir()
  seen <- new.env(parent = emptyenv())
  seen$args <- NULL
  nm <- reg_rw_tool("tt_rw", function(x) {
    seen$args <- list(x = x)
    paste0("OK: ", x)
  })

  cfg <- dairh_config_default()
  cfg$max_steps <- 50
  remover <- dairh_add_hook("pre_tool", function(name, args) {
    if (identical(name, nm)) dairh_rewrite_args(list(x = paste0(args$x, "-rw")))
  })
  withr::defer(remover(), envir = parent.frame())

  tools <- dairh_agent_tools(cfg)
  res <- tools[[nm]](x = "orig")
  expect_match(res, "OK: orig-rw", fixed = TRUE)
  expect_identical(seen$args$x, "orig-rw")

  # trace records the rewrite chain (hook name)
  df <- dairh_trace(n = 5)
  hit <- df[df$tool == nm, ]
  expect_true(nrow(hit) >= 1L)
  expect_identical(hit$args_rewritten[[nrow(hit)]], "hook1")
})

test_that("rewrite chain composes; malformed rewrite is ignored with warning", {
  local_rw_trace_dir()
  nm <- reg_rw_tool("tt_rw2", function(x) paste0("OK: ", x))
  cfg <- dairh_config_default()
  cfg$max_steps <- 50
  r1 <- dairh_add_hook("pre_tool", function(name, args) {
    if (identical(name, "tt_rw2")) dairh_rewrite_args(list(x = paste0(args$x, "-a")))
  })
  r2 <- dairh_add_hook("pre_tool", function(name, args) {
    if (identical(name, "tt_rw2")) dairh_rewrite_args(list(x = paste0(args$x, "-b")))
  })
  r3 <- dairh_add_hook("pre_tool", function(name, args) {
    # malformed marker: args not a list -> warn + ignore
    if (identical(name, "tt_rw2")) {
      structure(list(args = "nope"), class = "dairh_hook_rewrite")
    }
  })
  withr::defer(r1(), envir = parent.frame())
  withr::defer(r2(), envir = parent.frame())
  withr::defer(r3(), envir = parent.frame())

  tools <- dairh_agent_tools(cfg)
  expect_warning(res <- tools[["tt_rw2"]](x = "o"), "hook3", fixed = TRUE)
  expect_match(res, "OK: o-a-b", fixed = TRUE)
})

test_that("veto (string return) still wins over rewrite", {
  local_rw_trace_dir()
  nm <- reg_rw_tool("tt_rw3", function(x) paste0("OK: ", x))
  cfg <- dairh_config_default()
  cfg$max_steps <- 50
  remover <- dairh_add_hook("pre_tool", function(name, args) {
    if (identical(name, "tt_rw3")) {
      if (identical(args$x, "block")) "no-way" else dairh_rewrite_args(list(x = paste0(args$x, "-rw")))
    }
  })
  withr::defer(remover(), envir = parent.frame())

  tools <- dairh_agent_tools(cfg)
  expect_match(tools[[nm]](x = "block"), "FAIL", fixed = TRUE)
  expect_match(tools[[nm]](x = "go"), "OK: go-rw", fixed = TRUE)
})

test_that("post_tool hooks do not run on Content results", {
  local_rw_trace_dir()
  # register a tool that returns a Content list directly
  p <- tempfile(fileext = ".png")
  grDevices::png(p, width = 400, height = 400)
  graphics::plot(1:3)
  grDevices::dev.off()
  withr::defer(unlink(p), envir = parent.frame())
  dairh_register_tool("tt_content", function(x) {
    list(ellmer::ContentText(text = paste0("OK: ", x)), ellmer::content_image_file(p))
  }, "content returning tool",
    arguments = list(x = ellmer::type_string("x", required = TRUE)),
    overwrite = TRUE
  )
  withr::defer(dairh_unregister_tool("tt_content"), envir = parent.frame())

  cfg <- dairh_config_default()
  cfg$max_steps <- 50
  dairh_add_hook("post_tool", function(name, args, result) paste0(result, " [post]"))
  withr::defer(dairh_remove_hook("post_tool", "hook1"), envir = parent.frame())

  tools <- dairh_agent_tools(cfg)
  out <- tools[["tt_content"]](x = "keep")
  expect_true(is.list(out))
  expect_match(out[[1]]@text, "OK: keep", fixed = TRUE)   # untouched by [post]
})
