# 0.4 \u4F1A\u8BDD\u6301\u4E45\u5316\u63A5\u7EBF\uFF1Ahistory \u914D\u7F6E\u95F8\u95E8 / store \u9009\u9879\u6784\u9020 / \u6700\u8FD1\u4F1A\u8BDD\u626B\u63CF
test_that("history options: off/on/title gates", {
  cfg <- daiRH:::dairh_config_default()
  # daemon_mode \u672A\u5F00\uFF08gadget/\u8BBE\u7F6E\u9875\uFF09\u2192 FALSE\uFF0C\u4E0D\u78B0\u6301\u4E45\u5316
  expect_false(daiRH:::.dairh_history_options(cfg))

  withr::with_options(list(daiRH.daemon_mode = TRUE), {
    o <- daiRH:::.dairh_history_options(cfg)
    expect_s3_class(o, "chat_history_config")
    expect_identical(o$scope, "daiRH")
    expect_identical(o$title, "auto")
    expect_true(inherits(o$store, "FileConversationStore"))
    expect_true(inherits(o$store, "ConversationStore"))

    cfg2 <- cfg
    cfg2$history_title <- FALSE
    expect_null(daiRH:::.dairh_history_options(cfg2)$title)

    cfg3 <- cfg
    cfg3$history <- FALSE
    expect_false(daiRH:::.dairh_history_options(cfg3))
  })
})

test_that("latest conversation id scan", {
  d <- file.path(withr::local_tempdir(), "conversations")
  # \u76EE\u5F55\u4E0D\u5B58\u5728 \u2192 NULL\uFF08\u9996\u542F\u7A7A\u5E93\u4E0D\u62A5\u9519\uFF09
  expect_null(daiRH:::.dairh_history_latest_id(d))
  dir.create(file.path(d, "part", "c1"), recursive = TRUE)
  writeLines('{"id":"c_abc","title":"x"}',
    file.path(d, "part", "c1", "record.json"))
  Sys.sleep(0.05)
  dir.create(file.path(d, "part", "c2"), recursive = TRUE)
  writeLines('{"id":"c_def","title":"y"}',
    file.path(d, "part", "c2", "record.json"))
  expect_identical(daiRH:::.dairh_history_latest_id(d), "c_def")
  # \u574F\u8BB0\u5F55\u8DF3\u8FC7\uFF0C\u56DE\u9000\u5230\u6B21\u65B0
  Sys.sleep(0.05)
  dir.create(file.path(d, "part", "c3"), recursive = TRUE)
  writeLines("not json", file.path(d, "part", "c3", "record.json"))
  expect_identical(daiRH:::.dairh_history_latest_id(d), "c_def")
})

test_that("config defaults and roundtrip carry history fields", {
  d <- daiRH:::dairh_config_default()
  expect_true(isTRUE(d$history))
  expect_true(isTRUE(d$history_title))
  withr::local_options(daiRH.config_path = tempfile(fileext = ".json"))
  daiRH::dairh_config_set(history = FALSE, history_title = FALSE)
  got <- daiRH::dairh_config_get()
  expect_false(isTRUE(got$history))
  expect_false(isTRUE(got$history_title))
})
