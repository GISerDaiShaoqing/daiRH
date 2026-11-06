# Context compaction (0.6): transcript rendering / summary + rehydration /
# budget reset + trace / CLI dispatch. All ASCII; Chinese must use \uXXXX.

# fake agent: environment with get_turns/set_turns + harness state attr
.dairh_test_fake_agent <- function(turns) {
  st <- new.env(parent = emptyenv())
  st$trace <- TRUE
  st$trace_file <- NULL
  st$n_calls <- 3L
  st$last_user_n <- 2L
  st$budget <- 12L
  st$tag <- "main"
  env <- new.env(parent = emptyenv())
  env$turns <- turns
  env$get_turns <- function() env$turns
  env$set_turns <- function(x) {
    env$turns <- x
    invisible(x)
  }
  attr(env, ".dairh_state") <- st
  env
}

test_that("turns transcript renders text turns and skips empty ones", {
  t1 <- ellmer::Turn(role = "user",
    contents = list(ellmer::ContentText(text = "hello world")))
  t2 <- ellmer::Turn(role = "assistant",
    contents = list(ellmer::ContentText(text = "hi there")))
  t3 <- ellmer::Turn(role = "user", contents = list())
  out <- .dairh_turns_transcript(list(t1, t2, t3))
  expect_match(out, "USER: hello world", fixed = TRUE)
  expect_match(out, "ASSISTANT: hi there", fixed = TRUE)
  expect_length(strsplit(out, "\n\n", fixed = TRUE)[[1]], 2L)
  # over-long transcript goes through .dai_clip: head+tail kept, middle dropped
  out2 <- .dairh_turns_transcript(list(t1, t2), max_chars = 10)
  expect_match(out2, "\u5185\u5BB9\u8FC7\u957F", fixed = TRUE)
  expect_false(grepl("ASSISTANT", out2, fixed = TRUE))
  expect_true(startsWith(out2, "USER:"))
})

test_that("empty conversation refuses compaction without touching turns", {
  a <- .dairh_test_fake_agent(list())
  res <- .dairh_compact_turns(a, dairh_config_default())
  expect_false(res$ok)
  expect_true(is.character(res$msg) && nzchar(res$msg))
  expect_length(a$turns, 0L)
})

test_that("compact: summary -> set_turns rehydration + budget reset + trace", {
  tmp <- file.path(tempdir(), paste0("dairh-cpt-", as.integer(Sys.time()),
    "-", Sys.getpid()))
  dir.create(tmp, recursive = TRUE, showWarnings = FALSE)
  withr::defer(unlink(tmp, recursive = TRUE, force = TRUE))
  withr::local_options(daiRH.trace_dir = tmp)
  turns <- list(
    ellmer::Turn(role = "user",
      contents = list(ellmer::ContentText(text = "please analyze iris"))),
    ellmer::Turn(role = "assistant",
      contents = list(ellmer::ContentText(text = "done, wrote analysis.R")))
  )
  a <- .dairh_test_fake_agent(turns)
  testthat::local_mocked_bindings(
    dairh_client = function(cfg = dairh_config_get(), system_prompt = NULL) {
      list(chat = function(prompt) "SUMMARY-BODY")
    },
    .package = "daiRH"
  )
  res <- .dairh_compact_turns(a, dairh_config_default())
  expect_true(res$ok)
  expect_equal(res$n_old, 2L)
  expect_identical(res$summary, "SUMMARY-BODY")
  # rehydration: two turns user/assistant, summary embedded in the user turn
  nt <- a$turns
  expect_length(nt, 2L)
  expect_identical(as.character(nt[[1]]@role), "user")
  expect_identical(as.character(nt[[2]]@role), "assistant")
  expect_match(paste(nt[[1]]@text, collapse = ""), "SUMMARY-BODY", fixed = TRUE)
  # budget state reset
  st <- attr(a, ".dairh_state")
  expect_identical(st$n_calls, 0L)
  expect_true(is.na(st$last_user_n))
  # trace compact event
  p <- list.files(tmp, pattern = "^trace-.*[.]jsonl$", full.names = TRUE)
  expect_length(p, 1L)
  ln <- jsonlite::parse_json(readLines(p, warn = FALSE)[[1]], simplifyVector = FALSE)
  expect_identical(ln$type, "compact")
  expect_equal(as.numeric(ln$n_old), 2)
  expect_equal(as.numeric(ln$summary_chars), nchar("SUMMARY-BODY"))
})

test_that("summarizer failure propagates to caller (panel/CLI handle display)", {
  a <- .dairh_test_fake_agent(list(
    ellmer::Turn(role = "user",
      contents = list(ellmer::ContentText(text = "hi")))
  ))
  testthat::local_mocked_bindings(
    dairh_client = function(...) stop("boom", call. = FALSE),
    .package = "daiRH"
  )
  expect_error(.dairh_compact_turns(a, dairh_config_default()), "boom")
  # turns untouched
  expect_length(a$turns, 1L)
})

test_that("CLI /compact dispatch applies compaction", {
  a <- .dairh_test_fake_agent(list(
    ellmer::Turn(role = "user",
      contents = list(ellmer::ContentText(text = "task"))),
    ellmer::Turn(role = "assistant",
      contents = list(ellmer::ContentText(text = "ok")))
  ))
  testthat::local_mocked_bindings(
    dairh_client = function(...) list(chat = function(p) "CLI-SUMMARY"),
    .package = "daiRH"
  )
  act <- .dai_cli_command("/compact", agent = a, cfg = dairh_config_default())
  expect_identical(act, "ok")
  expect_length(a$turns, 2L)
  expect_match(paste(a$turns[[1]]@text, collapse = ""), "CLI-SUMMARY", fixed = TRUE)
  # agent unavailable degrades gracefully
  act2 <- .dai_cli_command("/compact", agent = NULL, cfg = dairh_config_default())
  expect_identical(act2, "ok")
})

test_that("CLI /compact on short conversation reports failure, keeps turns", {
  a <- .dairh_test_fake_agent(list())
  act <- .dai_cli_command("/compact", agent = a, cfg = dairh_config_default())
  expect_identical(act, "ok")
  expect_length(a$turns, 0L)
})
