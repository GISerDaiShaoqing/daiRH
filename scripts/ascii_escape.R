# 把 R 源码里的非 ASCII 字面量（含注释）统一转成 \uXXXX / \U######## 大写转义，
# 保证 R 源在任意 locale 下解析一致（Rd 例外：Rd 必须字面 UTF-8，走 fix_rd.R）。
# 用法：Rscript scripts/ascii_escape.R [包目录]（默认仓库根 = 本脚本上级目录的上级）
# 只改写 R/*.R 与 tests/testthat/*.R；幂等（已是纯 ASCII 的行不动）。
args_in <- commandArgs(trailingOnly = TRUE)
pkg <- if (length(args_in) >= 1) args_in[[1]] else {
  file.path(dirname(script <- sub("^--file=", "", grep("^--file=", commandArgs(), value = TRUE))),
    "..")
}
pkg <- normalizePath(pkg, winslash = "/", mustWork = TRUE)
files <- c(
  list.files(file.path(pkg, "R"), pattern = "[.]R$", full.names = TRUE),
  list.files(file.path(pkg, "tests", "testthat"), pattern = "[.]R$", full.names = TRUE)
)
esc_one <- function(line) {
  if (!grepl("[^\\x00-\\x7F]", line, perl = TRUE)) return(line)
  ch <- strsplit(line, "", useBytes = FALSE)[[1]]
  paste0(vapply(ch, function(x) {
    cp <- utf8ToInt(x)
    if (is.na(cp) || cp <= 126L) return(x)
    if (cp <= 65535L) sprintf("\\u%04X", cp) else sprintf("\\U%08X", cp)
  }, FUN.VALUE = character(1), USE.NAMES = FALSE), collapse = "")
}
changed <- 0L
for (f in files) {
  ln <- readLines(f, warn = FALSE, encoding = "UTF-8")
  new <- vapply(ln, esc_one, FUN.VALUE = character(1), USE.NAMES = FALSE)
  if (!identical(new, ln)) {
    con <- file(f, open = "wb")
    writeLines(new, con, sep = "\n", useBytes = TRUE)
    close(con)
    changed <- changed + 1L
    cat("escaped:", basename(f), "\n")
  }
}
cat("共改写", changed, "个文件\n")
for (f in files) parse(f)
cat("PARSE OK\n")
