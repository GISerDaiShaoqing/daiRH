# \u5305\u521D\u59CB\u5316\u4E0E locale \u9632\u7EBF ----------------------------------------------

# C locale \u9632\u7EBF\uFF080.9 \u5B9E\u6D4B\u8E29\u5751\uFF09\uFF1Asprintf/paste \u4E00\u7C7B\u539F\u751F\u7F16\u7801\u8F6C\u6362\u5728"\u8868\u793A\u4E0D\u4E86
# \u4E2D\u6587"\u7684 locale\uFF08LC_CTYPE=C/POSIX\u2014\u2014RStudio \u4F1A\u8BDD\u5E38\u89C1 LC_CTYPE=C.UTF-8
# \u8BBE\u7F6E\u5931\u8D25\u540E\u56DE\u9000\uFF09\u91CC\uFF0C\u4F1A\u628A UTF-8 \u5B57\u7B26\u4E32\u9000\u5316\u6210 <U+XXXX> \u5B57\u9762\u6587\u672C\u2014\u2014shiny
# selectInput \u7684\u4E0B\u62C9\u9009\u9879\u6B63\u662F\u8FD9\u4E48\u574F\u7684\uFF08\u6807\u7B7E\u8D70 htmltools \u6807\u7B7E\u8DEF\u5F84\u5E78\u5B58\uFF09\u3002
# \u5305\u52A0\u8F7D\u65F6\u53D1\u73B0\u65AD\u7EBF\u5C31\u628A LC_CTYPE \u62E8\u5230 Windows ucrt \u7684 ".UTF-8"\uFF1BGBK \u7B49
# \u672C\u5C31\u80FD\u8868\u793A\u4E2D\u6587\u7684 locale \u4E0D\u52A8\uFF1B\u5931\u8D25\u9759\u9ED8\uFF08\u8BB0\u8D26/\u5BF9\u8BDD\u4E0D\u53D7\u5F71\u54CD\uFF09\u3002
.dai_ensure_utf8_ctype <- function() {
  if (.Platform$OS.type != "windows") return(invisible(FALSE))
  loc <- tryCatch(Sys.getlocale("LC_CTYPE"), error = function(e) "")
  if (!identical(loc, "C") && !identical(loc, "POSIX") && nzchar(loc)) {
    return(invisible(FALSE))
  }
  tryCatch(
    Sys.setlocale("LC_CTYPE", ".UTF-8"),
    error = function(e) NULL
  )
  invisible(TRUE)
}

.onLoad <- function(libname, pkgname) {
  .dai_ensure_utf8_ctype()
  invisible(NULL)
}
