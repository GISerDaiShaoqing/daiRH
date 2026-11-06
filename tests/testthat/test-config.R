# All test source stays ASCII-only so parsing is locale-robust.
# Chinese assertions use <- <- \uXXXX escapes.

test_that("config roundtrip and default fallback", {
  tmp <- file.path(tempdir(), paste0("daiRH-test-", as.integer(Sys.time()), "-", Sys.getpid()))
  dir.create(tmp, recursive = TRUE)
  p <- file.path(tmp, "config.json")
  options(daiRH.config_path = p)
  on.exit(options(daiRH.config_path = NULL), add = TRUE)

  old <- dairh_config_get()
  expect_equal(old$provider, "ollama")

  dairh_config_set(
    provider = "openai_compatible",
    base_url = "https://api.deepseek.com",
    model = "deepseek-chat",
    temperature = 0.3,
    allow_run = FALSE
  )
  got <- dairh_config_get()
  expect_equal(got$provider, "openai_compatible")
  expect_equal(got$base_url, "https://api.deepseek.com")
  expect_equal(got$model, "deepseek-chat")
  expect_false(got$allow_run)
  expect_equal(got$temperature, 0.3)
  expect_true(isTRUE(got$restrict_paths))
})

test_that("api key resolution (3 forms)", {
  expect_equal(dairh_api_key_value(list(api_key = "sk-literal", api_key_env = "")),
    "sk-literal"
  )
  Sys.setenv(DaiRH_TMP_TESTKEY = "env-value")
  on.exit(Sys.unsetenv("DaiRH_TMP_TESTKEY"), add = TRUE)
  expect_equal(
    dairh_api_key_value(list(api_key = "env:DaiRH_TMP_TESTKEY", api_key_env = "")),
    "env-value"
  )
  expect_equal(
    dairh_api_key_value(list(api_key = "", api_key_env = "DaiRH_TMP_TESTKEY")),
    "env-value"
  )
  expect_equal(
    dairh_api_key_value(list(api_key = "", api_key_env = "DaiRH_NOT_SET_XXX")),
    ""
  )
})

test_that("0.5 config fields: dirs / subagent settings", {
  tmp <- file.path(tempdir(), paste0("daiRH-test-05-",
    as.integer(Sys.time()), "-", Sys.getpid()))
  dir.create(tmp, recursive = TRUE)
  p <- file.path(tmp, "config.json")
  options(daiRH.config_path = p)
  on.exit(options(daiRH.config_path = NULL), add = TRUE)

  dairh_config_set(
    history_dir = "D:/chat-history", trace_dir = "D:/traces",
    allow_subagent = FALSE, subagent_max_steps = 5
  )
  got <- dairh_config_get()
  expect_equal(got$history_dir, "D:/chat-history")
  expect_equal(got$trace_dir, "D:/traces")
  expect_false(got$allow_subagent)
  expect_equal(got$subagent_max_steps, 5)

  # history dir resolution: cfg wins, default falls back to user data dir
  expect_identical(.dairh_history_dir(got), "D:/chat-history")
  expect_identical(.dairh_history_dir(dairh_config_default()),
    file.path(tools::R_user_dir("daiRH", "data"), "conversations"))
})
