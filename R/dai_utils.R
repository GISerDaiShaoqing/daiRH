# \u901A\u7528\u5C0F\u5DE5\u5177 ---------------------------------------------------------------

`%||%` <- function(x, y) if (is.null(x) || length(x) == 0L || is.na(x)[1]) y else x

# \u622A\u65AD\u5B57\u7B26\u4E32\uFF0C\u8D85\u957F\u53EA\u4FDD\u7559\u5934\u5C3E
.dai_clip <- function(x, max_chars = 6000) {
  x <- as.character(x)
  if (!length(x)) return("")
  s <- paste(x, collapse = "\n")
  if (nchar(s, type = "chars") <= max_chars) return(s)
  head <- substring(s, 1, floor(max_chars * 0.7))
  tailc <- substring(s, nchar(s, type = "chars") - floor(max_chars * 0.25) + 1)
  paste0(head, "\n...\uFF08\u5185\u5BB9\u8FC7\u957F\uFF0C\u5DF2\u622A\u65AD\uFF09...\n", tailc)
}

# \u884C\u53F7\u683C\u5F0F\u5316
.dai_numbered <- function(lines, from = 1L) {
  w <- max(3L, nchar(as.character(from + length(lines) - 1L)))
  paste0(sprintf(sprintf("%%%dd| ", w), seq.int(from, from + length(lines) - 1L)), lines)
}
