# \u7F16\u8F91\u5668\u4E0A\u4E0B\u6587\u683C\u5F0F\u5316\uFF1A\u672A\u4FDD\u5B58\u6587\u6863\u652F\u6301 + \u9009\u533A\u884C\u53F7\u63D0\u53D6\u3002
# \u5173\u952E\uFF1Arstudioapi \u7684 document_position \u662F\u5E26\u540D\u5B57\u7684\u539F\u5B50\u5411\u91CF
# structure(c(row=, column=), class=...)\uFF0C\u4E0D\u662F list\u2014\u2014\u6D4B\u8BD5\u5FC5\u987B\u7528\u771F\u5B9E\u5F62\u72B6\u3002
test_that("editor context formats unsaved docs and selections", {
  pos <- function(r, c) structure(c(row = r, column = c),
    class = "document_position")
  ctx <- list(
    id = "1", path = "", contents = "a\nbb\nccc",
    selection = list(list(
      range = list(start = pos(2, 0), end = pos(3, 1)),
      text = "bb\nccc"
    ))
  )
  txt <- daiRH:::.dairh_format_editor_ctx(ctx)
  expect_true(grepl("\u672A\u4FDD\u5B58\u7684\u65E0\u6807\u9898\u6587\u6863", txt))
  expect_true(grepl("\u3010\u6D3B\u52A8\u6587\u4EF6\u3011", txt))
  expect_true(grepl("\u3010\u5F53\u524D\u9009\u533A\u3011\u7B2C 2\u20133 \u884C", txt))
  expect_true(grepl("2| bb", txt, fixed = TRUE))

  ctx2 <- list(id = "2", path = "E:/proj/f.R", contents = "x <- 1\ny <- 2",
    selection = list())
  txt2 <- daiRH:::.dairh_format_editor_ctx(ctx2)
  expect_true(grepl("f.R", txt2, fixed = TRUE))
  expect_false(grepl("\u3010\u5F53\u524D\u9009\u533A\u3011", txt2))

  expect_match(daiRH:::.dairh_format_editor_ctx(list(path = "", contents = "")),
    "\u6CA1\u6709\u53EF\u8BFB\u53D6")
})

test_that("pos row extraction handles atomic document_position", {
  atomic <- structure(c(row = 7, column = 2), class = "document_position")
  expect_identical(daiRH:::.dairh_pos_row(atomic, 1L), 7L)
  expect_identical(daiRH:::.dairh_pos_row(list(row = 4, column = 0), 1L), 4L)
  expect_identical(daiRH:::.dairh_pos_row(NULL, 1L), 1L)
  expect_identical(daiRH:::.dairh_pos_row(c(5, 9), 1L), 5L)
})
