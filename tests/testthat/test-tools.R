test_that("tools generated per safety toggles", {
  cfg <- dairh_config_default()
  tools <- dairh_agent_tools(cfg)

  expect_type(tools, "list")
  must <- c("read_file", "list_files", "run_r_code", "get_r_help",
    "workspace_summary", "get_editor_context", "create_file", "edit_file"
  )
  expect_true(all(must %in% names(tools)))

  cfg_no <- cfg
  cfg_no$allow_edit <- FALSE
  cfg_no$allow_run <- FALSE
  tools_no <- dairh_agent_tools(cfg_no)
  expect_false("run_r_code" %in% names(tools_no))
  expect_false("edit_file" %in% names(tools_no))
  expect_true("read_file" %in% names(tools_no))
})

test_that("system prompt includes key parts", {
  sp <- daiRH:::dairh_system_prompt(dairh_config_default())
  expect_match(sp, "DaiRH")
  expect_match(sp, "edit_file")
  expect_match(sp, "get_r_help")
  expect_match(sp, "R version 4", fixed = TRUE)
})

test_that("quick task prompts", {
  four <- c("explain", "explain_selection", "review", "docs")
  for (k in four) {
    p <- dairh_quick_prompt(k)
    expect_true(nzchar(p))
  }
  expect_match(dairh_quick_prompt("explain"), "get_editor_context")
  expect_match(dairh_quick_prompt("review"), "get_editor_context")
  expect_match(
    dairh_quick_prompt("docs", detail = "geom_point"),
    "geom_point"
  )
})

test_that("addin registry fields and bindings", {
  dcf_path <- system.file("rstudio", "addins.dcf", package = "daiRH")
  if (!nzchar(dcf_path)) {
    skip("daiRH not installed; skip addins.dcf validation")
  }
  dcf <- read.dcf(dcf_path)
  expect_true(all(c("Name", "Description", "Binding", "Interactive") %in%
    colnames(dcf)))
  bindings <- as.character(dcf[, "Binding"])
  expect_true(all(c("dairh_addin_chat", "dairh_addin_settings") %in% bindings))
  ns_path <- system.file("NAMESPACE", package = "daiRH")
  ns_lines <- readLines(ns_path)
  funs <- sub("^export\\(([^)]+)\\)\\s*$", "\\1",
    ns_lines[grepl("^export\\(", ns_lines)]
  )
  expect_true(all(bindings %in% funs))
})
