test_that("unique-match replace: hit / multi / missing", {
  r <- .dai_replace_once("x <- a\ny <- a\nz <- 1", "z <- 1", "z <- 2")
  expect_true(r$ok)
  expect_equal(r$text, "x <- a\ny <- a\nz <- 2")

  # "a" appears twice -> must fail (message is non-ASCII; only assert prefix)
  r2 <- .dai_replace_once("x <- a\ny <- a\nz <- 1", "a", "B")
  expect_false(r2$ok)
  expect_match(r2$msg, "^FAIL: ")

  r3 <- .dai_replace_once("abc", "def", "ghi")
  expect_false(r3$ok)
  expect_match(r3$msg, "^FAIL: ")
})

test_that("create/edit/read real files", {
  dir <- tempdir()
  p <- file.path(dir, "daiRH-tmp-test.R")
  on.exit(unlink(p), add = TRUE)

  m <- .dai_create_file(p, "a <- 1\nb <- 2\n", base = dir, restrict = TRUE)
  expect_match(m, "OK: ")

  m2 <- .dai_edit_file(p, "b <- 2", "b <- 3", base = dir, restrict = TRUE)
  expect_match(m2, "OK: ")
  expect_match(m2, "\\+ b <- 3")
  expect_equal(readLines(p), c("a <- 1", "b <- 3"))

  rd <- .dai_read_file(p, 1, 10, base = dir, restrict = TRUE)
  expect_match(rd, "b <- 3")
  expect_match(rd, "1\\| a <- 1")
})

test_that("path guard: restrict blocks outside of base", {
  # guard returns FAIL (not an error) via tool wrappers -> check FAIL string
  m <- .dai_read_file("C:/Windows/win.ini", 1, NULL, base = tempdir(), restrict = TRUE)
  expect_match(m, "FAIL: ")
  # calling the guard directly throws
  expect_error(.dai_path_guard("/etc/passwd", base = tempdir(), restrict = TRUE))
})

test_that("diff excerpt generation", {
  d <- .dai_diff_excerpt(c("a", "b", "c"), c("a", "b2", "c"))
  expect_true(any(grepl("^- b$", d)))
  expect_true(any(grepl("^\\+ b2$", d)))
})
