# Locale guard (0.9): package load repairs a broken C/POSIX LC_CTYPE.
# All ASCII; Chinese (if any) must go through \uXXXX escapes.

test_that("dai_ensure_utf8_ctype is safe and idempotent", {
  before <- Sys.getlocale("LC_CTYPE")
  expect_silent(.dai_ensure_utf8_ctype())
  expect_silent(.dai_ensure_utf8_ctype())
  after <- Sys.getlocale("LC_CTYPE")
  expect_true(nzchar(after))
  # a healthy (representable) locale is never changed
  if (!identical(before, "C") && !identical(before, "POSIX") && nzchar(before)) {
    expect_identical(after, before)
  }
})
