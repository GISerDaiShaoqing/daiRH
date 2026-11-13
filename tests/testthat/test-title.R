# Title generation (0.9): lightweight-model titling via the shinychat title hook.
# All ASCII; Chinese (if any) must go through \uXXXX escapes.

test_that(".dairh_title_norm cleans model output", {
  expect_identical(.dairh_title_norm("  My Great Analysis  "), "My Great Analysis")
  expect_identical(.dairh_title_norm("\"My Great Analysis\""), "My Great Analysis")
  expect_identical(.dairh_title_norm("'quoted'."), "quoted")
  expect_identical(.dairh_title_norm("Multi\nLine\tTitle"), "Multi Line Title")
  expect_identical(.dairh_title_norm(NULL), "")
  long <- paste(rep("word", 30), collapse = " ")
  out <- .dairh_title_norm(long)
  expect_true(nchar(out, type = "chars") <= 60)
  expect_identical(out, paste0(substr(long, 1L, 57L), "..."))
})

test_that(".dairh_title_excerpt builds user/assistant excerpt from turns", {
  turns <- list(
    ellmer::Turn(role = "user",
      contents = list(ellmer::ContentText(text = "help me analyze iris"))),
    ellmer::Turn(role = "assistant",
      contents = list(ellmer::ContentText(text = "sure, here is the plan"))),
    ellmer::Turn(role = "user",
      contents = list(ellmer::ContentText(text = "second question")))
  )
  ex <- .dairh_title_excerpt(turns)
  expect_match(ex, "user: help me analyze iris", fixed = TRUE)
  expect_match(ex, "assistant: sure, here is the plan", fixed = TRUE)
  expect_false(grepl("second question", ex, fixed = TRUE))
  # no user turn at all: NULL
  expect_null(.dairh_title_excerpt(list(
    ellmer::Turn(role = "assistant",
      contents = list(ellmer::ContentText(text = "x")))
  )))
  expect_null(.dairh_title_excerpt(NULL))
  # long text gets clipped to cap
  long <- paste(rep("w", 600), collapse = "")
  ex2 <- .dairh_title_excerpt(list(
    ellmer::Turn(role = "user", contents = list(ellmer::ContentText(text = long)))
  ))
  expect_true(nchar(ex2, type = "chars") <= 6 + 500)
})

test_that(".dairh_title_client builds only for a distinct lightweight model", {
  cfg <- dairh_config_default()
  cfg$provider <- "openai_compatible"
  cfg$base_url <- "http://127.0.0.1:9"
  # empty title_model: stay on the main model
  expect_null(.dairh_title_client(cfg))
  # same as main model: no separate client
  cfg$title_model <- cfg$model
  expect_null(.dairh_title_client(cfg))
  # distinct lightweight model: client builds offline (openai_compatible)
  cfg$title_model <- "cheap-model"
  tc <- .dairh_title_client(cfg)
  expect_false(is.null(tc))
})

test_that(".dairh_title_fn tri-state", {
  cfg <- dairh_config_default()
  cfg$history_title <- FALSE
  expect_null(.dairh_title_fn(cfg, NULL))
  cfg$history_title <- TRUE
  # no lightweight model: keep shinychat's default clone path
  expect_identical(.dairh_title_fn(cfg, NULL), "auto")
  # lightweight model configured: custom function (not called here -> no network)
  cfg$provider <- "openai_compatible"
  cfg$base_url <- "http://127.0.0.1:9"
  cfg$title_model <- "cheap-model"
  expect_true(is.function(.dairh_title_fn(cfg, NULL)))
})
