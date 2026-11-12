# daiRH 站点重建唯一入口（在包根目录运行：Rscript dev/build_site.R）
#
# 为什么不走裸 pkgdown::build_site()：pkgdown 会把 docs/LICENSE{,-text}.{html,md}
# 页面原样写进站点，而 GitHub 的 licensee 要求全部 license 候选恰好匹配同一种
# 许可证——这些页面（HTML 模板页/重排页/纯文本页）匹配不成 MIT，会把整仓徽章
# 判成 Other。本脚本在构建后把四个许可页统一重写为 LICENSE 正文（与根目录
# LICENSE 同文本），保证候选唯一。
#
# 已知代价：根 LICENSE 是全文 MIT 而非 DCF 桩（YEAR:/COPYRIGHT HOLDER:），
# R CMD check --as-cran 出 1 条 NOTE "License stub is invalid or otherwise
# unusable by CRAN"——renv 上 CRAN 即此布局，0 error/0 warning 门禁不受影响。
# 另：不要再跑 usethis::use_mit_license()，它会把 LICENSE 重置回两行桩。

if (!file.exists("DESCRIPTION"))
  stop("请在 daiRH 包根目录运行本脚本（未找到 DESCRIPTION）", call. = FALSE)

pkgdown::build_site(preview = FALSE, quiet = TRUE, new_process = FALSE)

mit <- readLines("LICENSE", warn = FALSE)
rewritten <- character(0)
for (f in file.path("docs", c("LICENSE.html", "LICENSE-text.html",
                              "LICENSE.md", "LICENSE-text.md"))) {
  if (file.exists(f)) {
    con <- file(f, open = "wb")
    writeLines(mit, con, sep = "\n", useBytes = TRUE)
    close(con)
    rewritten <- c(rewritten, f)
  }
}

# 构建后自检：自定义域名与英文落地页必须存活
stopifnot(file.exists(file.path("docs", "CNAME")),
          file.exists(file.path("docs", "en", "index.html")))

cat("站点已重建；许可页已重写为 LICENSE 正文：",
    if (length(rewritten)) paste(rewritten, collapse = ", ") else "(无)",
    "\n")
