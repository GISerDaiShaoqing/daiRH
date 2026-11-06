# DaiRH \u6280\u80FD\u5E93\uFF08skills\uFF09-------------------------------------------------------
# \u7EA6\u5B9A\u76EE\u5F55\uFF1AR_user_dir("daiRH", "data")/skills/\uFF08\u53EF\u628A\u9886\u57DF\u89C4\u7A0B\u3001\u4EE3\u7801\u6A21\u677F\u3001\u56E2\u961F
# \u7EA6\u5B9A\u5199\u5728\u8FD9\u91CC\uFF0CAgent \u6309\u9700\u8BFB\u53D6\uFF0C\u4E0D\u5360\u5E38\u9A7B\u4E0A\u4E0B\u6587\uFF09\uFF1A
#   - <name>.md            \u5355\u6587\u4EF6\u6280\u80FD
#   - <name>/SKILL.md      \u76EE\u5F55\u5F62\u6001\u6280\u80FD\uFF08\u6B63\u6587\u91CC\u53EF\u7528\u76F8\u5BF9\u8DEF\u5F84\u63D0\u53CA\u540C\u76EE\u5F55\u9644\u4EF6\uFF09
# Agent \u4FA7\u53EA\u6709\u4E00\u4E2A read_skill \u5DE5\u5177\uFF1A\u7A7A\u53C2\u5217\u51FA\u6E05\u5355\uFF0C\u7ED9\u540D\u8BFB\u5168\u6587\uFF08\u6E10\u8FDB\u5F0F\u52A0\u8F7D\uFF09\u3002

#' \u6280\u80FD\u5E93\u76EE\u5F55
#'
#' \u8FD4\u56DE\u6280\u80FD\u5E93\u76EE\u5F55\u8DEF\u5F84\uFF08\u4E0D\u5B58\u5728\u5219\u521B\u5EFA\uFF09\u3002\u76EE\u5F55\u7EA6\u5B9A\u89C1 [dairh_read_skill()]\uFF1A
#' \u6BCF\u4E2A `<name>.md` \u6216 `<name>/SKILL.md` \u662F\u4E00\u4E2A\u6280\u80FD\uFF0CAgent \u53EF\u901A\u8FC7 read_skill
#' \u5DE5\u5177\u5217\u51FA\u5E76\u6309\u540D\u8BFB\u53D6\u3002\u6D4B\u8BD5\u53EF\u7528 option `daiRH.skills_dir` \u8986\u76D6\u3002
#'
#' @return \u76EE\u5F55\u8DEF\u5F84\uFF08\u5B57\u7B26\u5411\u91CF\uFF0C\u957F\u5EA6 1\uFF09
#' @export
dairh_skills_dir <- function() {
  d <- getOption("daiRH.skills_dir")
  if (is.null(d) || !is.character(d) || !nzchar(d)) {
    d <- file.path(tools::R_user_dir("daiRH", "data"), "skills")
  }
  dir.create(d, recursive = TRUE, showWarnings = FALSE)
  d
}

# \u626B\u6280\u80FD\u5E93\uFF1A\u8FD4\u56DE\u547D\u540D\u5217\u8868 name -> \u6587\u4EF6\u8DEF\u5F84\uFF08\u5355\u6587\u4EF6\u4E0E\u76EE\u5F55\u5F62\u6001\u90FD\u6536\uFF09
.dairh_skill_files <- function(dir = dairh_skills_dir()) {
  out <- list()
  flat <- list.files(dir, pattern = "\\.md$", full.names = TRUE, ignore.case = TRUE)
  for (f in flat) {
    nm <- tools::file_path_sans_ext(basename(f))
    if (nzchar(nm)) out[[nm]] <- f
  }
  subs <- list.dirs(dir, recursive = FALSE)
  for (s in subs) {
    f <- file.path(s, "SKILL.md")
    if (file.exists(f)) out[[basename(s)]] <- f
  }
  out[sort(names(out))]
}

# read_skill \u5DE5\u5177\u4F53\uFF08\u53EF\u5355\u6D4B\uFF09\uFF1Aname \u7A7A\u5219\u5217\u6E05\u5355\uFF0C\u5426\u5219\u8BFB\u5168\u6587
.dai_read_skill <- function(name = "") {
  name <- if (is.null(name)) "" else trimws(paste(as.character(name), collapse = " "))
  files <- tryCatch(.dairh_skill_files(), error = function(e) list())
  if (!nzchar(name)) {
    if (!length(files)) {
      return(paste0(
        "\u6280\u80FD\u5E93\u4E3A\u7A7A\u3002\u6280\u80FD\u76EE\u5F55\uFF1A", dairh_skills_dir(),
        "\uFF08\u653E\u5165 <\u540D\u5B57>.md \u6216 <\u540D\u5B57>/SKILL.md \u5373\u53EF\u88AB Agent \u8BFB\u53D6\uFF09"
      ))
    }
    lines <- vapply(names(files), function(nm) {
      first <- tryCatch({
        l <- readLines(files[[nm]], n = 6L, warn = FALSE)
        l <- l[nzchar(trimws(l))]
        if (length(l)) trimws(substr(l[[1]], 1L, 80L)) else ""
      }, error = function(e) "")
      sprintf("  %s: %s", nm, first)
    }, character(1), USE.NAMES = FALSE)
    return(paste0(c(
      paste0("\u53EF\u7528\u6280\u80FD\uFF08", length(files),
        " \u4E2A\uFF0C\u76EE\u5F55 ", dairh_skills_dir(), "\uFF09\uFF1A"),
      lines
    ), collapse = "\n"))
  }
  # \u540D\u5B57\u767D\u540D\u5355 + \u53EA\u5141\u8BB8\u547D\u4E2D\u626B\u63CF\u7ED3\u679C\uFF08\u675C\u7EDD\u8DEF\u5F84\u7A7F\u8D8A\uFF09
  if (!grepl("^[A-Za-z0-9_.-]+$", name) || is.null(files[[name]])) {
    return(paste0("FAIL: \u6CA1\u6709\u53EB ", name, " \u7684\u6280\u80FD\u3002\u53EF\u7528\uFF1A",
      if (length(files)) paste(names(files), collapse = ", ") else "\uFF08\u6280\u80FD\u5E93\u4E3A\u7A7A\uFF09"))
  }
  f <- files[[name]]
  size <- tryCatch(file.info(f)$size, error = function(e) NA_real_)
  if (!is.finite(size)) return(paste0("FAIL: \u6280\u80FD\u6587\u4EF6\u4E0D\u53EF\u8BFB: ", f))
  if (size > 64e3) {
    return(paste0("FAIL: \u6280\u80FD\u6587\u4EF6\u8FC7\u5927\uFF08", round(size / 1e3),
      " KB > 64 KB\uFF09\uFF0C\u8BF7\u62C6\u5206\u6280\u80FD\u3002"))
  }
  txt <- paste(readLines(f, warn = FALSE, encoding = "UTF-8", skipNul = TRUE), collapse = "\n")
  paste0(c(paste0("[\u6280\u80FD] ", name, " (", f, ")"), txt), collapse = "\n")
}

#' \u67E5\u770B\u6280\u80FD\u5E93\u6E05\u5355
#'
#' \u7B49\u4EF7\u4E8E Agent \u7684 read_skill \u5DE5\u5177\u7559\u7A7A\u8C03\u7528\uFF1A\u5217\u51FA\u6280\u80FD\u5E93\u91CC\u5F53\u524D\u53EF\u7528\u7684\u6280\u80FD\u540D\u4E0E
#' \u9996\u884C\u7B80\u4ECB\u3002\u9002\u5408\u914D\u7F6E\u5B8C\u6280\u80FD\u540E\u5FEB\u901F\u81EA\u68C0\u3002
#'
#' @return \u6280\u80FD\u8BF4\u660E\u6587\u672C\uFF08\u5B57\u7B26\u5411\u91CF\uFF0C\u957F\u5EA6 1\uFF09
#' @export
dairh_read_skill <- function(name = "") {
  out <- .dai_read_skill(name)
  cat(out, "\n")
  invisible(out)
}
