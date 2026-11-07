# Usage log (0.6): resolve contract / jsonl append / env bypass / on_request_end hook.
# All ASCII; Chinese (if any) must go through \uXXXX escapes.

test_that("dairh_usage_resolve handles numeric(3) and named-list forms", {
  expect_null(.dairh_usage_resolve(NULL))
  # ellmer runtime form: numeric(3) = c(input, output, cached_input)
  r <- .dairh_usage_resolve(c(10, 5, 4))
  expect_equal(r$input, 10)
  expect_equal(r$output, 5)
  expect_equal(r$cache_read, 4)
  # cancelled request form: all NA -> zeros
  r0 <- .dairh_usage_resolve(c(NA_real_, NA_real_, NA_real_))
  expect_equal(r0$input, 0)
  expect_equal(r0$output, 0)
  expect_equal(r0$cache_read, 0)
  # defensive named-list form, missing field defaults to 0
  r2 <- .dairh_usage_resolve(list(input = 1, output = 2))
  expect_equal(r2$cache_read, 0)
  # junk values are coerced to 0
  r3 <- .dairh_usage_resolve(list(input = NA_real_, output = -5, cached_input = "x"))
  expect_equal(r3$input, 0)
  expect_equal(r3$output, 0)
  expect_equal(r3$cache_read, 0)
})

test_that("dai_fmt_tokens formats counts for the header pill", {
  expect_identical(.dai_fmt_tokens(0), "0")
  expect_identical(.dai_fmt_tokens(999), "999")
  expect_identical(.dai_fmt_tokens(12345), "12.3k")
  expect_identical(.dai_fmt_tokens(2500000), "2.5M")
  expect_identical(.dai_fmt_tokens(NA), "0")
  expect_identical(.dai_fmt_tokens("junk"), "0")
})

test_that("usage log appends one jsonl line per request", {
  tmp <- file.path(tempdir(), paste0("dairh-usage-", as.integer(Sys.time()),
    "-", Sys.getpid()))
  withr::local_options(daiRH.usage_dir = tmp)
  ok1 <- .dairh_usage_log("m1", list(input = 3, output = 7, cache_read = 1))
  ok2 <- .dairh_usage_log("m2", list(input = 1, output = 0), ok = FALSE)
  expect_true(ok1)
  expect_true(ok2)
  p <- file.path(tmp, "usage.jsonl")
  lines <- readLines(p, warn = FALSE)
  expect_length(lines, 2L)
  j1 <- jsonlite::parse_json(lines[[1]], simplifyVector = FALSE)
  expect_identical(j1$source, "daiRH")
  expect_identical(j1$model, "m1")
  expect_true(j1$ok)
  expect_equal(as.numeric(j1$input), 3)
  expect_equal(as.numeric(j1$cache_read), 1)
  expect_false(jsonlite::parse_json(lines[[2]], simplifyVector = FALSE)$ok)
})

test_that("DAIRH_USAGE_LOG=0 bypasses logging entirely", {
  tmp <- file.path(tempdir(), paste0("dairh-usage-byp-",
    as.integer(Sys.time()), "-", Sys.getpid()))
  withr::local_options(daiRH.usage_dir = tmp)
  withr::local_envvar(DAIRH_USAGE_LOG = "0")
  expect_false(.dairh_usage_log("m", list(input = 1, output = 1)))
  expect_false(file.exists(file.path(tmp, "usage.jsonl")))
})

test_that("usage install registers callback; skips zero-usage turns, logs real ones", {
  tmp <- file.path(tempdir(), paste0("dairh-usage-cb-",
    as.integer(Sys.time()), "-", Sys.getpid()))
  withr::local_options(daiRH.usage_dir = tmp)
  cbs <- list()
  fake <- list(on_request_end = function(cb) cbs[[length(cbs) + 1L]] <<- cb)
  cl <- .dairh_usage_install(fake, "mm")
  # 0.7: install also attaches a rate env, so identical() on the list would see
  # the new attribute -- assert the return value is the same object instead.
  expect_true(is.environment(attr(cl, ".dairh_rate")))
  expect_length(cbs, 1L)
  # empty turn (tokens default all-NA) -> no line written
  turn_empty <- ellmer::Turn(role = "assistant",
    contents = list(ellmer::ContentText(text = "x")))
  invisible(cbs[[1]](turn_empty))
  expect_false(file.exists(file.path(tmp, "usage.jsonl")))
  # real usage -> exactly one line with model + fields
  turn_full <- ellmer::Turn(role = "assistant",
    contents = list(ellmer::ContentText(text = "y")), tokens = c(6, 2, 0))
  invisible(cbs[[1]](turn_full))
  p <- file.path(tmp, "usage.jsonl")
  expect_true(file.exists(p))
  lines <- readLines(p, warn = FALSE)
  expect_length(lines, 1L)
  j <- jsonlite::parse_json(lines[[1]], simplifyVector = FALSE)
  expect_identical(j$model, "mm")
  expect_equal(as.numeric(j$input), 6)
  expect_equal(as.numeric(j$output), 2)
  expect_true(is.null(j$cost))
})

test_that("usage install honors DAIRH_USAGE_LOG=0 at registration time", {
  cbs2 <- list()
  fake2 <- list(on_request_end = function(cb) cbs2[[length(cbs2) + 1L]] <<- cb)
  withr::local_envvar(DAIRH_USAGE_LOG = "0")
  .dairh_usage_install(fake2, "mm")
  expect_length(cbs2, 0L)
})

# 0.7: request timing / tok-per-second in the funnel + rate env for the panel
test_that("usage funnel records duration_s and tok_per_s; rate env exposed", {
  tmp <- file.path(tempdir(), paste0("dairh-usage-rate-",
    as.integer(Sys.time()), "-", Sys.getpid()))
  withr::local_options(daiRH.usage_dir = tmp)
  starts <- list()
  cbs <- list()
  fake <- list(
    on_request_start = function(cb) starts[[length(starts) + 1L]] <<- cb,
    on_request_end = function(cb) cbs[[length(cbs) + 1L]] <<- cb
  )
  cl <- .dairh_usage_install(fake, "m-rate")
  expect_length(starts, 1L)
  expect_length(cbs, 1L)
  renv <- attr(cl, ".dairh_rate")
  expect_true(is.environment(renv))
  # no network sleeps: pin the start stamp 2s in the past
  renv$t0 <- Sys.time() - 2
  turn <- ellmer::Turn(role = "assistant",
    contents = list(ellmer::ContentText(text = "z")), tokens = c(10, 50, 0))
  invisible(cbs[[1]](turn))
  lines <- readLines(file.path(tmp, "usage.jsonl"), warn = FALSE)
  expect_length(lines, 1L)
  j <- jsonlite::parse_json(lines[[1]], simplifyVector = FALSE)
  expect_equal(as.numeric(j$duration_s), 2, tolerance = 0.2)
  rate <- as.numeric(j$tok_per_s)
  expect_true(rate > 20 && rate < 30)
  # rate env keeps (turn, rate); turn identity lets the panel filter title clones
  expect_true(identical(renv$last$turn, turn))
  expect_equal(as.numeric(renv$last$tok_per_s), rate)
  # cancelled (all-NA) request: no new line, rate not overwritten
  renv$t0 <- Sys.time() - 1
  turn_na <- ellmer::Turn(role = "assistant",
    contents = list(ellmer::ContentText(text = "w")))
  invisible(cbs[[1]](turn_na))
  lines2 <- readLines(file.path(tmp, "usage.jsonl"), warn = FALSE)
  expect_length(lines2, 1L)
  expect_true(identical(renv$last$turn, turn))
})

test_that("install tolerates clients without on_request_start (end-only fakes)", {
  tmp <- file.path(tempdir(), paste0("dairh-usage-endonly-",
    as.integer(Sys.time()), "-", Sys.getpid()))
  withr::local_options(daiRH.usage_dir = tmp)
  cbs3 <- list()
  fake3 <- list(on_request_end = function(cb) cbs3[[length(cbs3) + 1L]] <<- cb)
  cl3 <- .dairh_usage_install(fake3, "mm")
  expect_length(cbs3, 1L)
  expect_true(is.environment(attr(cl3, ".dairh_rate")))
})
