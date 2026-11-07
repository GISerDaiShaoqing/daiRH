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

test_that("0.6 preset static model lists (GET /models fallback)", {
  oc <- DAI_LLM_PRESETS[["opencode.go"]]
  expect_true(is.character(oc$models) && length(oc$models) >= 5L)
  expect_true("glm-5.3-flash" %in% oc$models)
  expect_false(anyNA(oc$models))
  expect_true(all(nzchar(oc$models)))
  ds <- DAI_LLM_PRESETS[["deepseek.chat"]]
  expect_identical(sort(ds$models), c("deepseek-chat", "deepseek-reasoner"))
  # ollama relies on dynamic discovery: no static list needed
  expect_null(DAI_LLM_PRESETS[["ollama.local"]]$models)
})

test_that("0.6 context_window config field (numeric coerce, blank = NA)", {
  tmp <- file.path(tempdir(), paste0("daiRH-test-cw-",
    as.integer(Sys.time()), "-", Sys.getpid()))
  dir.create(tmp, recursive = TRUE)
  p <- file.path(tmp, "config.json")
  options(daiRH.config_path = p)
  on.exit(options(daiRH.config_path = NULL), add = TRUE)

  # default unknown
  expect_true(is.na(dairh_config_get()$context_window))
  dairh_config_set(context_window = 1000000)
  expect_equal(dairh_config_get()$context_window, 1e6)
  # blank string coerces to NA (unknown window)
  dairh_config_set(context_window = "")
  expect_true(is.na(dairh_config_get()$context_window))
})

# 0.7: session mode / delegate model / reasoning effort
test_that("0.7 config fields: defaults, coercion and normalization", {
  cfg <- dairh_config_default()
  expect_identical(cfg$mode, "build")
  expect_identical(cfg$delegate_model, "")
  expect_identical(cfg$reasoning_effort, "")

  tpl <- dairh_config_default()
  expect_identical(.dai_cfg_coerce("mode", "PLAN", tpl), "plan")
  expect_identical(.dai_cfg_coerce("mode", "junk", tpl), "build")
  expect_identical(.dai_cfg_coerce("mode", character(0), tpl), "build")
  expect_identical(.dai_cfg_coerce("mode", " plan ", tpl), "plan")
  expect_identical(.dai_cfg_coerce("reasoning_effort", "HIGH", tpl), "high")
  expect_identical(.dai_cfg_coerce("reasoning_effort", "minimal", tpl), "minimal")
  expect_identical(.dai_cfg_coerce("reasoning_effort", "nope", tpl), "")
  expect_identical(.dai_cfg_coerce("reasoning_effort", character(0), tpl), "")
  # delegate_model is a free-form string (trimmed at the use site)
  expect_identical(.dai_cfg_coerce("delegate_model", " tiny-model ", tpl), " tiny-model ")
})

test_that("0.7 mode persists through config roundtrip", {
  tmp <- file.path(tempdir(), paste0("daiRH-test-mode-",
    as.integer(Sys.time()), "-", Sys.getpid()))
  dir.create(tmp, recursive = TRUE)
  p <- file.path(tmp, "config.json")
  options(daiRH.config_path = p)
  on.exit(options(daiRH.config_path = NULL), add = TRUE)

  dairh_config_set(mode = "plan", reasoning_effort = "medium",
    delegate_model = "tiny-model")
  got <- dairh_config_get()
  expect_identical(got$mode, "plan")
  expect_identical(got$reasoning_effort, "medium")
  expect_identical(got$delegate_model, "tiny-model")
  expect_true(.dairh_is_plan_mode(got))
})
