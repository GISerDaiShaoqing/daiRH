# man/*.Rd 修整：roxygenise 之后跑一次。
#   1) 把 Rd 里的 \uXXXX 转义还原成真实 UTF-8 字符
#      （Rd 格式不支持 \u 转义——R 代码里合法、Rd 里一律 unknown macro，
#       CI 四平台实测；R 源码保持转义形态不动，注释/文档不参与运行时）
#   2) 给每个 Rd 注入 \encoding{UTF-8}（老工具链兼容）
# 用法：R.exe --vanilla --no-echo -f scripts/fix_rd.R （在包根目录）
# 本机注意：必须用 R.exe（Rscript 会段错误）。

fix_rd_one <- function(path) {
  # 纯字节操作：C locale 下 readLines/readBin 原样进出字节，
  # 不做任何 encoding 标记/转换（enc2utf8 会把已有 UTF-8 字节搅成乱码）
  bytes <- readBin(path, "raw", n = file.info(path)$size)
  txt <- rawToChar(bytes) # roxygen 产出的 Rd 是纯 ASCII（转义形态）
  orig <- txt

  # 1) \encoding{UTF-8} 注入（放在 \name{...} 节之后）
  if (!grepl("encoding{UTF-8}", txt, fixed = TRUE)) {
    m <- regexpr("(?s)\\\\name\\{[^}]*\\}", txt, perl = TRUE)
    if (m[[1]] >= 0) {
      end <- m[[1]] + attr(m, "match.length")[[1L]]
      txt <- paste0(
        substring(txt, 1L, end), "\n\\encoding{UTF-8}",
        substring(txt, end + 1L)
      )
    }
  }

  # 2) \uXXXX 转义 -> 真实 UTF-8 字节（字节级拼接，避免编码机器）
  pat <- "[\\\\]u[0-9A-Fa-f]{4}"
  m2 <- gregexpr(pat, txt, perl = TRUE)[[1]]
  out <- raw(0)
  if (m2[[1]] >= 0) {
    starts <- as.integer(m2)
    lens <- as.integer(attr(m2, "match.length"))
    hits <- substring(txt, starts, starts + lens - 1L)
    cps <- strtoi(substring(hits, 3L), 16L)
    b_in <- charToRaw(txt) # 此刻 txt 仍是纯 ASCII（插入的标记也是 ASCII）
    pos <- 1L
    for (i in seq_along(starts)) {
      if (starts[i] > pos) {
        out <- c(out, b_in[pos:(starts[i] - 1L)])
      }
      cp <- cps[i]
      out <- c(out, if (cp < 0x80) {
        as.raw(cp)
      } else if (cp < 0x800) {
        as.raw(c(
          bitwOr(0xC0, bitwShiftR(cp, 6)),
          bitwOr(0x80, bitwAnd(cp, 0x3F))
        ))
      } else {
        as.raw(c(
          bitwOr(0xE0, bitwShiftR(cp, 12)),
          bitwOr(0x80, bitwAnd(bitwShiftR(cp, 6), 0x3F)),
          bitwOr(0x80, bitwAnd(cp, 0x3F))
        ))
      })
      pos <- starts[i] + lens[i]
    }
    if (pos <= length(b_in)) {
      out <- c(out, b_in[pos:length(b_in)])
    }
  } else {
    out <- charToRaw(txt)
  }

  if (!identical(paste(out, collapse = ""), paste(charToRaw(orig), collapse = ""))) {
    con <- file(path, open = "wb")
    writeBin(out, con)
    close(con)
    invisible(TRUE)
  } else {
    invisible(FALSE)
  }
}

args <- grep("^--file=", commandArgs(FALSE), value = TRUE)
pkg_dir <- if (length(args)) {
  dirname(dirname(sub("^--file=", "", args[[1]])))
} else {
  getwd()
}
man_dir <- file.path(pkg_dir, "man")

n <- 0L
for (f in list.files(man_dir, pattern = "\\.Rd$", full.names = TRUE)) {
  done <- fix_rd_one(f)
  n <- n + isTRUE(done)
  cat(basename(f), if (isTRUE(done)) "[fixed]" else "[clean]", "\n")
}
cat("fixed:", n, "\n")
