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

# \u4ECE document_position \u63D0\u53D6\u884C\u53F7\u3002rstudioapi \u7684 document_position \u662F\u5E26\u540D\u5B57\u7684
# \u539F\u5B50\u6570\u503C\u5411\u91CF structure(c(row=, column=), class=...)\uFF0C\u4E0D\u662F list\u2014\u2014\u5BF9\u5B83\u7528
# $ \u53D6 row \u4F1A\u62A5 "$ operator is invalid for atomic vectors"\uFF080.4 \u73B0\u573A\u4E8B\u6545\uFF1A
# \u53EA\u8981\u771F\u6709\u9009\u533A\uFF0C\u4E0A\u4E0B\u6587\u9009\u533A\u5757\u5C31\u70B8/\u88AB\u541E\uFF09\u3002[[ ]] \u5BF9\u539F\u5B50\u547D\u540D\u5411\u91CF\u4E0E list \u90FD\u6210\u7ACB\u3002
.dairh_pos_row <- function(pos, default = 1L) {
  if (is.null(pos)) return(default)
  r <- tryCatch(pos[["row"]], error = function(e) NULL)
  if (is.null(r) && is.numeric(pos) && length(pos) >= 1L) r <- pos[[1L]]
  r <- suppressWarnings(as.integer(r))
  if (is.na(r)) default else r
}
