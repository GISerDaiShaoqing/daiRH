# daiRH 维护手册（AGENTS.md）

给未来维护本包的人类与 AI 助手。改动任何代码前先读一遍”硬规矩”，
再按”常用流程”走；版本发布走”发布清单”。

## 这是什么

`daiRH` 是 RStudio 里的对话式编程 Agent + harness：面板跑在 callr 子进程
（控制台不被占用），每次工具调用经过统一治理层（注册表 / pre-post 钩子 /
单回合硬步数预算 / jsonl trace）。三个前端共享同一套 Agent：Viewer
面板、 经典 gadget、控制台
CLI（[`dairh_cli()`](https://giserdaishaoqing.github.io/daiRH/reference/dairh_cli.md)）。

- 发布渠道：GitHub `GISerDaiShaoqing/daiRH`，文档站
  `https://giserdaishaoqing.github.io/daiRH/`（Pages，main 分支 /docs
  目录）
- CI：GitHub Actions 四平台（windows/ubuntu/macos × R
  release/oldrel-1）， `error-on: "warning"`——任何 WARNING
  都会导致红，别只在本地跑通就算完

## 硬规矩（.public 面,违反任一都算事故）

1.  **代码、文档、测试、示例、issue
    文案里不得出现**：内网/校园服务器地址、 任何 API
    key、密钥样式的字面量。默认端点一律 `http://localhost:11434`。
2.  **密钥只放用户自己的 config.json 或环境变量**（`api_key_env` /
    `env:变量名`），仓库与包产物里永远没有密钥副本。
3.  **git 由维护者本人执行**（commit / push /
    tag）。助手只改文件、跑测试， 最多做只读的 `git status/log/diff`。
4.  `R CMD check` 维持四平台零 ERROR 零 WARNING；新增依赖必须给下限版本
    并说明理由。
5.  测试新增用例全 ASCII（中文一律走 `\uXXXX` 转义，见编码管线）。

## 编码管线（本项目最关键的约定）

- **R 源（R/*.R、tests/testthat/*.R）**：非 ASCII 一律
  `\uXXXX`（大写十六进制） 转义形式，含注释。写完样带字面中文后必须跑：

  ``` sh
  Rscript scripts/ascii_escape.R <包目录>
  ```

  （幂等；文件必须可 [`parse()`](https://rdrr.io/r/base/parse.html)
  才算过。）

- \*\*Rd（man/\*.Rd）\*\*：永远字面 UTF-8，Rd 不支持 `\u`
  转义。roxygenise 后跑：

  ``` sh
  Rscript scripts/fix_rd.R
  ```

  它按字节流把 .Rd 里的转义重新解码。

- 两轨不可混：R 源转义、Rd 字面。CI 已经用翻车现场验证过这个分工。

## 代码结构速查

| 文件 | 职责 |
|----|----|
| `R/config.R` | 配置读写/预设表（`DAI_LLM_PRESETS`）/coerce 模板 |
| `R/client.R` | provider→ellmer 客户端、模型列表、opencode 会话头 |
| `R/harness.R` | 注册表、钩子、硬预算、trace 写入（harness 核心） |
| `R/tools_agent.R` | 9 个内置工具（含 `.dai_path_guard` 路径限制闸） |
| `R/agent.R` | 系统提示词、[`dairh_new_agent()`](https://giserdaishaoqing.github.io/daiRH/reference/dairh_new_agent.md) 组装 |
| `R/context.R` | RStudio 编辑器上下文/主会话桥 |
| `R/background.R` | 后台模式：callr 面板子进程、能力桥、孤儿回收 |
| `R/app_shiny.R` | 面板 UI/CSS/设置 modal；shinychat 接线（chat_ui/chat_server） |
| `R/cli.R` | 控制台 CLI（readline 循环 + ellmer 流式回显） |
| `scripts/` | 维护工具（ascii_escape / fix_rd），已 .Rbuildignore |
| `_pkgdown.yml` + `docs/` | 站点配置与产物（docs 提交进 main） |

## 常用流程

``` sh
# 1) 单测（本地基线：FAIL 0 | WARN 1 | PASS 163；WARN 是已知良性项）
Rscript -e "library(daiRH); testthat::test_dir('tests/testthat', package='daiRH')"

# 2) 装进系统库（Windows 例）
R.exe --vanilla CMD INSTALL --no-multiarch -l <R 库目录> <包目录>

# 3) 手改了 roxygen 注释之后
Rscript -e "roxygen2::roxygenise('<包目录>' )"   # 再跟 scripts/fix_rd.R

# 4) pkgdown 站点重建（改了 README/NEWS/_pkgdown.yml/函数签名后）
Rscript -e "pkgdown::build_site('<包目录>', override=list(), preview=FALSE)"
```

## 依赖升级适配清单（每次 ellmer/shinychat/shiny 大版本升级照这个走）

1.  [`args()`](https://rdrr.io/r/base/args.html)
    全量核对用到的新旧签名（对照上一版签名表），特别是 lifecycle 标记
    `deprecated()` 的参数——传了必吐警告。
2.  在 R 源里 `grep` 调用点，确认废弃 API 零残留（历史注释除外）。
3.  **无头复现面板**：`shiny::runApp(list(ui=app$ui, server=app$server), port=<port>, launch.browser=FALSE)`
    起本地口，用浏览器自动化截图 + 量 DOM
    几何（`getBoundingClientRect`）定位布局问题；360–900px 宽度
    全走一遍再算适配完。
4.  新增驻留特性（如会话存储）先设计 harness 侧整合方案再接，避免 “UI
    一套状态、Agent 另一套”的错位。

## 发布清单

1.  改名包：`DESCRIPTION` Version → NEWS.md 顶部加段 → 测试全绿 →
    roxygenise + fix_rd.R → pkgdown 重建。
2.  `git status` 自查无额外杂物后由维护者 commit + push（等 CI
    四平台绿）。
3.  `git tag vX.Y.Z` 并推送；GitHub Release 页描述贴 NEWS 对应段落。
4.  发版前后跑一遍密钥足迹自检（仓库/tarball/历史三面）。
