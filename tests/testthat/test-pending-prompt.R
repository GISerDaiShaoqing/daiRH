# \u9009\u4E2D\u76F4\u53D1\u901A\u9053\uFF1A\u5F85\u53D1\u63D0\u793A\u7684\u6D88\u8D39\u903B\u8F91\uFF08\u6539\u540D\u62A2\u5360 / \u8D85\u9F84\u6E05\u7406 / \u53EA\u53D6\u6700\u65B0\uFF09
test_that("pending prompt take: consume once, race-guard, expiry", {
  d <- withr::local_tempdir()
  withr::local_options(daiRH.bridge_dir = d)
  # \u65E0\u6587\u4EF6 \u2192 NULL
  expect_null(daiRH:::.dairh_take_pending_prompt())

  # \u6B63\u5E38\u6D88\u8D39\uFF1A\u8FD4\u56DE\u6587\u672C\u3001\u539F\u6587\u4EF6\u6D88\u5931\uFF08\u6539\u540D\u63A5\u7BA1\uFF09\u3001\u518D\u53D6\u4E3A\u7A7A
  f <- file.path(d, "pending-prompt-a1.json")
  writeLines('{"text":"hello prompt","ts":"x"}', f)
  got <- daiRH:::.dairh_take_pending_prompt()
  expect_identical(got, "hello prompt")
  expect_false(file.exists(f))
  expect_null(daiRH:::.dairh_take_pending_prompt())

  # \u7ADE\u4E89\uFF1A\u88AB\u522B\u7684\u9762\u677F\u62A2\u5148\u6539\u540D \u2192 \u672C\u6B21\u62FF\u4E0D\u5230
  f2 <- file.path(d, "pending-prompt-b2.json")
  writeLines('{"text":"second"}', f2)
  stopifnot(file.rename(f2, paste0(f2, ".taken")))
  expect_null(daiRH:::.dairh_take_pending_prompt())

  # \u8D85\u9F84\uFF1A\u76F4\u63A5\u6E05\u6389\u4E0D\u6D88\u8D39
  f3 <- file.path(d, "pending-prompt-c3.json")
  writeLines('{"text":"old"}', f3)
  Sys.setFileTime(f3, Sys.time() - 3600)
  expect_null(daiRH:::.dairh_take_pending_prompt())
  expect_false(file.exists(f3))
})
