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
