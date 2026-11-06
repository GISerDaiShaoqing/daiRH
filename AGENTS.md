# daiRH 维护手册（AGENTS.md）

给未来维护本包的人类与 AI 助手。改动任何代码前先读一遍"硬规矩"，
再按"常用流程"走；版本发布走"发布清单"。

## 这是什么

`daiRH` 是 RStudio 里的对话式编程 Agent + harness：面板跑在 callr 子进程
（控制台不被占用），每次工具调用经过统一治理层（注册表 / pre-post 钩子 /
单回合硬步数预算 / jsonl trace）。三个前端共享同一套 Agent：Viewer 面板、
经典 gadget、控制台 CLI（`dairh_cli()`）。

- 发布渠道：GitHub `GISerDaiShaoqing/daiRH`，文档站 `https://gisersqdai.top/daiRH/`
  （GitHub Pages 自定义域名；**`docs/CNAME` 必须保持在库**，pkgdown 重建后要确认它没被清掉）
- CI：GitHub Actions 四平台（windows/ubuntu/macos × R release/oldrel-1），
  `error-on: "warning"`——任何 WARNING 都会导致红，别只在本地跑通就算完

## 硬规矩（.public 面,违反任一都算事故）

1. **代码、文档、测试、示例、issue 文案里不得出现**：内网/校园服务器地址、
   任何 API key、密钥样式的字面量。默认端点一律 `http://localhost:11434`。
2. **密钥只放用户自己的 config.json 或环境变量**（`api_key_env` /
   `env:变量名`），仓库与包产物里永远没有密钥副本。
3. **git 由维护者本人执行**（commit / push / tag）。助手只改文件、跑测试，
   最多做只读的 `git status/log/diff`。
4. `R CMD check` 维持四平台零 ERROR 零 WARNING；新增依赖必须给下限版本
   并说明理由。
5. 测试新增用例全 ASCII（中文一律走 `\uXXXX` 转义，见编码管线）。

## 编码管线（本项目最关键的约定）

- **R 源（R/*.R、tests/testthat/*.R）**：非 ASCII 一律 `\uXXXX`（大写十六进制）
  转义形式，含注释。写完样带字面中文后必须跑：

  ```sh
  Rscript scripts/ascii_escape.R <包目录>
  ```

  （幂等；文件必须可 `parse()` 才算过。）
- **Rd（man/*.Rd）**：永远字面 UTF-8，Rd 不支持 `\u` 转义。roxygenise 后跑：

  ```sh
  Rscript scripts/fix_rd.R
  ```

  它按字节流把 .Rd 里的转义重新解码。
- 两轨不可混：R 源转义、Rd 字面。CI 已经用翻车现场验证过这个分工。

## 代码结构速查

| 文件 | 职责 |
|---|---|
| `R/config.R` | 配置读写/预设表（`DAI_LLM_PRESETS`）/coerce 模板 |
| `R/client.R` | provider→ellmer 客户端、模型列表、opencode 会话头 |
| `R/harness.R` | 注册表、钩子（拦截/参数改写）、硬预算、trace 写入（harness 核心） |
| `R/tools_agent.R` | 内置工具（含 `.dai_path_guard` 路径限制闸；名单与 harness.R 的 `.dairh_builtin_tools()` 保持同步） |
| `R/agent.R` | 系统提示词、`dairh_new_agent()` 组装 |
| `R/subagent.R` | 子代理委派（delegate_task：独立 Chat、深度锁 1 层、独立预算） |
| `R/skills.R` | 技能库（约定目录 + read_skill 工具的渐进加载） |
| `R/context.R` | RStudio 编辑器上下文/主会话桥 |
| `R/background.R` | 后台模式：callr 面板子进程、能力桥、孤儿回收 |
| `R/app_shiny.R` | 面板 UI/CSS/设置 modal；shinychat 接线（chat_ui/chat_server） |
| `R/cli.R` | 控制台 CLI（readline 循环 + ellmer 流式回显） |
| `scripts/` | 维护工具（ascii_escape / fix_rd），已 .Rbuildignore |
| `_pkgdown.yml` + `docs/` | 站点配置与产物（docs 提交进 main） |

## 常用流程

```sh
# 1) 单测（必须走 test_local 加载源码包；library(daiRH)+test_dir 跑的是
#    已安装旧版——0.4 曾因此假红；不要加 --vanilla，C locale 下中文断言两侧
#    编码表征不一致会出假红）。本地基线：FAIL 0 | WARN 0 | PASS 261
Rscript -e "testthat::test_local('<包目录>')"

# 2) 装 CI 同参数的本地 R CMD check 门（0.5.1 之前缺这道门发生过：
#    Rd 漏 @param 四平台齐红）。判据 Status: OK。两个坑（实测）：
#    a. 必须在 PowerShell/cmd 里跑且清空 LANG/LC_CTYPE/LC_ALL/LANGUAGE——
#       Git Bash 的 C.UTF-8 会让 R 启动喷 "Setting LC_CTYPE failed"，
#       check 收集子进程 stderr 直接伪造 WARNING+ERROR；
#    b. 必须 --no-manual（CI 的 r-lib action 默认就带）：本地 pdflatex 对
#       中文 Rd 过不了 inputenc，纯噪声。
powershell -Command "foreach ($v in 'LANG','LC_CTYPE','LC_ALL','LANGUAGE'){Remove-Item Env:$v};
  $env:_R_CHECK_CRAN_INCOMING_='false'; $env:_R_CHECK_URLS_CRAN_='false';
  & '<R目录>/bin/R.exe' CMD build '<包目录>';
  & '<R目录>/bin/R.exe' CMD check --no-manual --as-cran '<包目录>_x.y.z.tar.gz'"
#    （powershell 要先 cd 到自己工作的临时目录里，build 产物落在那里）

# 3) 装进系统库（Windows 例）
R.exe --vanilla CMD INSTALL --no-multiarch -l <R 库目录> <包目录>

# 4) 手改了 roxygen 注释之后
Rscript -e "roxygen2::roxygenise('<包目录>' )"   # 再跟 scripts/fix_rd.R
#    注意：新函数/新形参必须配全 @param——--as-cran 把漏文档升成 ERROR

# 5) pkgdown 站点重建（改了 README/NEWS/_pkgdown.yml/函数签名后）
Rscript -e "pkgdown::build_site('<包目录>', override=list(), preview=FALSE)"
```

## 依赖升级适配清单（每次 ellmer/shinychat/shiny 大版本升级照这个走）

1. `args()` 全量核对用到的新旧签名（对照上一版签名表），特别是 lifecycle
   标记 `deprecated()` 的参数——传了必吐警告。
2. 在 R 源里 `grep` 调用点，确认废弃 API 零残留（历史注释除外）。
3. **无头复现面板**：`shiny::runApp(list(ui=app$ui, server=app$server),
   port=<port>, launch.browser=FALSE)` 起本地口，用浏览器自动化截图 +
   量 DOM 几何（`getBoundingClientRect`）定位布局问题；360–900px 宽度
   全走一遍再算适配完。
4. 新增驻留特性（如会话存储）先设计 harness 侧整合方案再接，避免
   "UI 一套状态、Agent 另一套"的错位。

**shinychat 避坑（实测）**：其客户端 markdown 管道允许 `<img>` 标签通过但会
剥掉 `data:` 协议的 src（imgCount=1、naturalWidth=0）——greeting/markdown
文本里内嵌图不可行。聊天插图走原生 contents 图片通道（show_plot 即此）；
静态 Logo 放面板自家标记（`.dai_title_logo()`，data URI 复用
`.dai_image_data_uri()` 并缓存）。

**magick 避坑（0.5.0 CI 四平台红实测）**：CI 不会安装项目没声明的重型包
（`setup-r-dependencies` 只按 DESCRIPTION 相依解析），而
`ellmer::content_image_file(..., resize != "none")` 内部 `check_installed("magick")`
非交互直接抛错。本地装了 magick 所以测试全绿、CI 才红假性"环境无关"。
规矩：测试里凡是构造图片显式传 `resize="none"`，或 `skip_if_not_installed("magick")`；
运行时代码涉及 magick 一律 tryCatch 降级（show_plot 就是 low→none 回退）。
不要把 magick 加进 DESCRIPTION（依赖太重）。

**安装树坑（实测）**：R 装包时不会把 `man/` 拷进安装树——`system.file("man","figures","logo.png")` 在已安装的包里返回空，函数静默退化成无 Logo（无头验证走 load_all 源码目录，测不出这层）。运行时资源双备份：`man/figures/`（源码位置，load_all 可见）+ `inst/figures/`（硬拷贝，安装树一定在），查找函数两条路径都试。

## 发布清单

1. 改名包：`DESCRIPTION` Version → NEWS.md 顶部加段 → 测试全绿 →
   roxygenise + fix_rd.R → **本地 R CMD check（`--no-manual --as-cran`，
   见常用流程第 2 步，Status: OK）** → pkgdown 重建。
   （0.5.0 曾因只跑单测不跑 as-cran 检查，`dairh_read_skill.Rd` 漏
   `@param name` 直接四平台齐红——warn 级才会伤盯 CI 的人，别省这道门）
2. **产出文档同步**（细节见"产出文档"一节）：维护者本地派生文档按新版口径
   过一遍才算发完。
3. `git status` 自查无额外杂物后由维护者 commit + push（等 CI 四平台绿）。
4. `git tag vX.Y.Z` 并推送；GitHub Release 页描述贴 NEWS 对应段落；
   `docs/CNAME` 仍在。
5. 发版前后跑一遍密钥足迹自检（仓库/tarball/历史三面）。

## 产出文档（规定）

- 存在一批**维护者本地维护的对外派生文档**（技术文章、论文材料、软著登记
  材料等），它们**不进包仓库**，与包目录平行的本地工作区集中存放。
- **同步义务**：每次发版（发布清单第 2 步）按新版口径同步这批文档；具体
  清单、路径与动作列表维护在产出工作区自己的 README 里，**不写入本文件**
  ——本文件是公开页（pkgdown 会把根目录 .md 收进站点），凡"仅存在于本地
  的事实"（文件路径、提交状态、日期）不得在此出现。
- 红线对其同样适用：不出现内网/校园地址、API key、上游工具品牌名；
  软著日期与证件信息永远只由维护者本人确定，助手只代笔技术内容。

## 文档站双语化（规定）

- **目标**：`https://gisersqdai.top/daiRH/` 中英双语——中文主站 + 英文入口，
  顶部互链语言切换。
- **现状（方案 B 已落地）**：中文主站内容不动；`_pkgdown.yml` 导航右侧挂
  `EN → en/index.html`（pkgdown 会按页面深度自动改写成 `../en/index.html`，
  0.5.0 后实测）；英文入口是**静态页** `docs/en/index.html`（复用主站
  `deps/` 资产与 logo，随发版手工同步内容）。已实测两个耐性：pkgdown 重建
  **不清除** `docs/en/`（自动生成 `en/index.md` 文本镜像，照抄 llm-docs
  机制），CNAME 不丢。函数参考仍以中文保留 + 英文页深链（功能页 usage 代码
  通用）；英文 NEWS 摘要后补。
- **升级路径（方案 A，暂缓）**：双 pkgdown 配置两份站点做多语言全镜像；
  参考页 Rd 说明全中文，全镜像前需要批量英化 roxygen 文案（成本高，等英
  文读者真实增长再上）。
- **同步义务**：英文页内容随发版同步（并入发布清单第 2 步）；若未来某次
  pkgdown 升级改变清理行为导致 `docs/en/` 被清，重建后按本节重新补回静态页。
