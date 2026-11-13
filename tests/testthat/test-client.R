# opencode session header injection (ASCII-only test file)

test_that("opencode gateway gets a stable x-opencode-session header", {
  h <- daiRH:::.dai_session_headers("https://opencode.ai/inference/go/openai/v1")
  expect_type(h, "character")
  expect_true(!is.null(h[["x-opencode-session"]]))
  expect_match(h[["x-opencode-session"]], "^daiRH-")

  h2 <- daiRH:::.dai_session_headers("https://opencode.ai/inference/go/openai/v1")
  # header type/value regenerates per client, always well-formed
  expect_match(h2[["x-opencode-session"]], "^daiRH-")
})

test_that("non-opencode endpoints get no session header", {
  expect_null(daiRH:::.dai_session_headers("https://api.deepseek.com"))
  expect_null(daiRH:::.dai_session_headers("http://192.0.2.55:11434/v1"))
})

test_that("openai_compatible client constructs without session headers (deepseek-like)", {
  cfg <- list(
    provider = "openai_compatible",
    base_url = "https://api.deepseek.com",
    model = "deepseek-chat",
    api_key = "sk-test",
    api_key_env = "",
    temperature = 0.2
  )
  cl <- daiRH::dairh_client(cfg)
  expect_s3_class(cl, "Chat")
})

test_that("opencode-style client constructs with session headers", {
  cfg <- list(
    provider = "openai_compatible",
    base_url = "https://opencode.ai/inference/go/openai/v1",
    model = "glm-5.3-flash",
    api_key = "oc_test",
    api_key_env = "",
    temperature = 0.7
  )
  cl <- daiRH::dairh_client(cfg)
  expect_s3_class(cl, "Chat")
})

# 0.7: rate env attached to every client; reasoning_effort accepted at construction
test_that("dairh_client attaches the rate env and accepts reasoning_effort", {
  cfg <- list(
    provider = "openai_compatible",
    base_url = "https://api.deepseek.com",
    model = "deepseek-chat",
    api_key = "sk-test",
    api_key_env = "",
    temperature = 0.2
  )
  cl <- daiRH::dairh_client(cfg)
  expect_true(is.environment(attr(cl, ".dairh_rate")))

  cfg2 <- cfg
  cfg2$base_url <- "http://127.0.0.1:9/v1" # never contacted at construction
  cfg2$reasoning_effort <- "high"
  cl2 <- daiRH::dairh_client(cfg2)
  expect_s3_class(cl2, "Chat")
  expect_true(is.environment(attr(cl2, ".dairh_rate")))
})

# 0.9: three gateway protocol modes - Responses (openai) and Messages (anthropic)
test_that("dairh_client builds Responses and Messages providers offline", {
  cfg <- list(
    provider = "openai",
    base_url = "http://127.0.0.1:9/v1", # never contacted at construction
    model = "m1",
    api_key = "sk-test",
    api_key_env = "",
    temperature = 0.2
  )
  cl <- daiRH::dairh_client(cfg)
  expect_s3_class(cl, "Chat")
  expect_true(is.environment(attr(cl, ".dairh_rate")))

  cfg$provider <- "anthropic"
  cl2 <- daiRH::dairh_client(cfg)
  expect_s3_class(cl2, "Chat")
  expect_true(is.environment(attr(cl2, ".dairh_rate")))
})

test_that("provider norm maps gateway template ids and rejects unknowns", {
  expect_identical(daiRH:::.dairh_norm_provider("opencode-go-chat"),
    "openai_compatible")
  expect_identical(daiRH:::.dairh_norm_provider("opencode-go-messages"),
    "anthropic")
  expect_identical(daiRH:::.dairh_norm_provider("opencode-go-responses"),
    "openai")
  expect_error(daiRH:::.dairh_norm_provider("nonsense-provider"), "provider")
})

# 0.9: gateway presets ship builtin model lists for all three protocol modes
test_that("gateway presets ship builtin model lists for all three modes", {
  p <- daiRH:::DAI_LLM_PRESETS
  expect_identical(p$`opencode.go.chat`$provider, "openai_compatible")
  expect_identical(p$`opencode.go.responses`$provider, "openai")
  expect_identical(p$`opencode.go.messages`$provider, "anthropic")
  expect_true("gpt-6-luna" %in% p$`opencode.go.responses`$models)
  expect_true("minimax-m3" %in% p$`opencode.go.messages`$models)
  expect_true(length(p$`opencode.go.chat`$models) >= 15)
})

# 0.9: temperature = NA omits the param (some models reject it with HTTP 400)
test_that("temperature NA omits the param; finite value keeps it", {
  p1 <- daiRH:::.dai_build_params(NA_real_, "")
  expect_false("temperature" %in% names(p1))
  p2 <- daiRH:::.dai_build_params(0.5, "")
  expect_equal(p2$temperature, 0.5)
  p3 <- daiRH:::.dai_build_params(NA_real_, "high")
  expect_false("temperature" %in% names(p3))
  expect_true("reasoning_effort" %in% names(p3))
})

# 0.9 regression: default 0.7 applies only when the field is MISSING;
# an explicitly-set NA must survive coalescing (it means "do not send")
test_that("temperature resolution: default only when missing; NA stays NA", {
  expect_equal(daiRH:::.dai_resolve_temperature(list()), 0.7)
  expect_true(is.na(daiRH:::.dai_resolve_temperature(list(temperature = NA_real_))))
  expect_equal(daiRH:::.dai_resolve_temperature(list(temperature = 0.5)), 0.5)
})
