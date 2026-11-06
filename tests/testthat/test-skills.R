# Skills library (0.5): directory scan + read_skill tool.
# All test source stays ASCII-only so parsing is locale-robust.

local_skills_dir <- function() {
  d <- file.path(tempdir(),
    paste0("dairh-skills-", as.integer(Sys.time()), "-", Sys.getpid()))
  dir.create(d, recursive = TRUE, showWarnings = FALSE)
  withr::local_options(daiRH.skills_dir = d, .local_envir = parent.frame())
  withr::defer(unlink(d, recursive = TRUE), envir = parent.frame())
  d
}

test_that("skills dir scan finds flat and nested skills", {
  d <- local_skills_dir()
  writeLines("flat skill body", file.path(d, "flat.md"))
  dir.create(file.path(d, "nested"), showWarnings = FALSE)
  writeLines("nested skill body", file.path(d, "nested", "SKILL.md"))

  fs <- .dairh_skill_files(d)
  expect_setequal(names(fs), c("flat", "nested"))
  expect_match(.dai_read_skill(""), "flat", fixed = TRUE)
  expect_match(.dai_read_skill(""), "nested", fixed = TRUE)
})

test_that("read_skill returns body; clean FAIL on missing/invalid names", {
  d <- local_skills_dir()
  writeLines("body-line", file.path(d, "alpha.md"))

  out <- .dai_read_skill("alpha")
  expect_match(out, "alpha", fixed = TRUE)
  expect_match(out, "body-line", fixed = TRUE)

  expect_match(.dai_read_skill("nope"), "FAIL", fixed = TRUE)
  expect_match(.dai_read_skill("../escape"), "FAIL", fixed = TRUE)
  expect_match(.dai_read_skill("a/b"), "FAIL", fixed = TRUE)
})

test_that("empty library reports the skills directory", {
  d <- local_skills_dir()
  out <- .dai_read_skill("")
  expect_match(out, d, fixed = TRUE)
})

test_that("oversized skill is rejected", {
  d <- local_skills_dir()
  big <- file.path(d, "big.md")
  writeLines(paste(rep("x", 70000), collapse = ""), big)
  expect_match(.dai_read_skill("big"), "64 KB", fixed = TRUE)
})

test_that("read_skill is exposed as a builtin tool", {
  local_skills_dir()
  tools <- dairh_agent_tools(dairh_config_default())
  expect_true("read_skill" %in% names(tools))
})
