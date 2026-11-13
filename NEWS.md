# daiRH 0.9.0

* **用量账本新增推理（思维链）明细 `reasoning_tokens`**：从请求的原始响应体
  `usage` 里取（turn 对象自带原始响应，Chat Completions 口径
  `completion_tokens_details$reasoning_tokens`，兜一手 Responses 口径
  `output_tokens_details$reasoning_tokens`）。已含在 `output` 内、仅明细
  拆分列，合计口径不变；端点未上报时整字段省略（与 `cost` 同款约定），
  老账本行照常兼容。
* **压缩触发提示（占用阈值）**：状态栏"上下文占用"达到模型窗口的阈值时
  读数变警示色并推送一次通知（`compact_hint`，默认 0.7，设置页可调 0~1，
  0 = 关；需已设置 `context_window`）。压缩/清空后占用降回阈值以下，
  自动重新武装，不会重复打扰。
* **轻量模型起标题 `title_model`**：留空 = 主模型（默认，与之前一致）。
  配置后新会话的自动标题改走轻量模型（`reasoning_effort` 强制置空——
  标题不需要思考），省主模型的账；标题请求照常进用量漏斗，账本按
  `title_model` 记账，外部监测工具可按模型分账。
* **思考过程展示开关 `show_thinking`（默认开）**：shinychat 0.5 原生渲染
  折叠思考块；设置页可关（走 shinychat 的 `show_thinking_after_s` 负值
  通道），重开面板生效。
* **服务接入补齐三种协议模式**：provider 新增 `openai`（OpenAI Responses
  协议，请求 `{base_url}/responses`）与 `anthropic`（Anthropic Messages
  协议，请求 `{base_url}/messages`），与网关的 chat / messages / responses
  三模板一一对应；provider 字段也接受模板 id（`opencode-go-chat/messages/
  responses` 自动归一）。思考强度在 Responses 走原生 params；Anthropic 侧
  不透传（budget 语义不同）。设置页 Provider 单选同步四选；预设新增
  `opencode.go.responses` / `opencode.go.messages`（内置模型清单照 ZCode
  模板），三模式的"列出模型"回退全部覆盖，另补 Anthropic 原生列模型
  （`GET {base_url}/models`，`x-api-key` + `anthropic-version` 头）。
  temperature 支持**留空 = 不发送**——Responses 推理模型等会拒收该字段
  （网关 400 "Unsupported parameter" 实测），设置页清空即绕开。
* **依赖地板升 ellmer ≥ 0.5.1**：思考强度透传回归单通道——`reasoning_effort`
  统一走 `params()`（上游 0.5.1 已修 compatible provider 的 params 白名单，
  本地假网关实测进请求体顶层），0.7 引入的 `api_args` 旁路撤销。
* **修复：设置页下拉选项显示 `<U+XXXX>` 乱码（0.7 起潜伏）**：部分 R 会话的
  `LC_CTYPE` 断到 C locale（`LC_CTYPE=C.UTF-8` 设置失败回退），运行期原生
  编码转换把 UTF-8 字符串退化成字面文本——shiny 下拉选项首当其冲（标签
  走另一条路径幸存，故"标签正常、选项乱码"）。两层修复：包加载时发现
  LC_CTYPE 断线自动拨回 `.UTF-8`（`R/zzz.R`）；安装纪律明确要求清空
  `LC_*` 再 `CMD INSTALL`（C locale 下安装解析会把坏字节写进安装树）。

# daiRH 0.8.0

* **压缩上下文：进度反馈 + 找回保险 + 状态栏旧账修正**：点击确认后弹出
  进度弹窗（CSS 转圈 + 说明文案），压缩完成自动关闭；压缩在同一个抽屉
  条目内原地完成（标题不变），压缩前自动把原对话存储三件套（记录图/
  消息正文/UI 转写）整树备份为「（压缩前备份）」条目——new_chat 是记录
  原地重开、旧轮次本不留副本，这一步才让"找回"名副其实（备份含形状
  校验，失败自动跳过、不阻断压缩）。另修：压缩/清空会替换对话轮次而
  shinychat 对此无感知，状态栏会一直显示旧账——现加显式刷新扳手，压缩
  时把旧账结转（累计不清零）、清空时归零。

* **状态栏"上下文占用"口径修正（缓存计费网关）**：缓存网关把完整 prompt 拆成
  两笔记账——`input` 只是未命中增量、缓存命中单列 `cache_read`，而命中部分
  照样占着上下文窗口。0.7 及之前面板只读 `input`，实测把 123k 的真实占用显示
  成"481 / 1.0M (0.0%)"，无法作为压缩时机依据。现改为 **input + cache_read**
  （最近一次请求的完整 prompt），窗口内百分比与压缩决策口径对齐；
  `usage.jsonl` 行格式不变（分账照旧）。
* **项目概览（上下文扩充，默认开）**：新会话系统提示自动带会话启动快照——
  git 分支/HEAD/未提交变更（system2，零新依赖）、目录树两层、工作区摘要
  （能力桥优先，回退本地）。无 git/空项目自动降级跳过；设置页可关
  （`project_brief`）；模式热切换时随系统提示词原地刷新。
* **面板左侧吉祥物可换**：config 新增 `mascot` 字段（本地路径或 http(s) URL，
  留空 = 内置小机器人 SVG），设置页可填路径或从电脑选图（副本存入 daiRH
  数据目录）。用第三方插画时请保留作者署名并自行确认授权。

# daiRH 0.7.0

* **plan/build 模式（头部按钮热切换）**：面板标题栏新增模式按钮（构建 ⇄ 计划，
  当场生效、对话与硬预算计数不丢）。计划模式 = 只读调研：运行时从最终工具集
  **物理裁掉** `create_file`/`edit_file`/`run_r_code`/`show_plot`/`show_html`
  （非提示词劝告），系统提示词换成"调研 + 交付结构化计划"口径；
  `delegate_task` 保留且子代理继承同一模式（天然只读），独立调研不受影响。
  控制台 `/plan` `/build` 同一实现；config 新增 `mode` 字段管新会话默认值
  （设置页可选）。核心实现：复用同一 state env 重建工具集 +
  `set_system_prompt()`/`set_tools()` 原地换（ellmer Chat 为 R6，shinychat
  起标题与历史重放即用此二机制），trace 记 `mode` 事件可审计。
* **子代理模型 delegate_model**：config 新增 `delegate_model`——子代理委派
  可指定轻量模型（留空沿用主模型），usage 日志 `model` 字段自动跟随对账；
  设置页高级区可填，重开面板生效。
* **tok/s 速度显示 + 请求时长落盘**：漏斗升级为 ellmer `on_request_start`/
  `on_request_end` 回调对——`usage.jsonl` 每行新增 `duration_s` 与
  `tok_per_s`（外部用量监测可算吞吐）；面板状态栏新增「· N tok/s」段，
  按 turn 对象一致性过滤（起标题的 clone 请求不污染主对话速度显示）。
* **工作时长**：状态栏新增计时——streaming 期间每秒活跳「⏱ 工作中
  m分s秒」（shinychat `status` 两态括弧，覆盖整个工具循环），结束冻结为
  「· 本轮 m分s秒」；开新会话从零计。
* **思考强度 reasoning_effort**：config 新增 `reasoning_effort`
  （minimal/low/medium/high，空 = 不发送）。双通道透传：openai_compatible
  走 `api_args` 直进请求体顶层——compatible provider 的 params 白名单不认
  `reasoning_effort`（请求时警告 Ignoring unsupported parameters 并丢弃，
  面板 stderr 实测后改道），ollama 走 `params()` 原生支持；网关探针实测
  接受。面板状态栏「思考:关/低/中/高」循环按钮（写配置持久化）+ 设置页
  下拉；ellmer Chat 无 params 热改口，重开面板生效（与模型选择器同语义）。
* **杂项**：新增 `R/mode.R`，无新增导出函数、无新增依赖；测试基线
  PASS 404。

# daiRH 0.6.0

* **手动压缩上下文**：面板输入框下方状态栏右侧新增压缩按钮，CLI 新增
  `/compact`——把当前会话（含工具调用链）交给主模型总结成结构化摘要（一次性
  无工具 Chat，1 次请求），随后 `set_turns()` 重水合：模型上下文替换为
  user(摘要) + assistant(确认) 两轮，单轮硬预算重置并写 trace `compact` 事件。
  面板侧原对话经 `new_chat()` 存入历史抽屉可随时找回，聊天记录保留并附压缩
  横幅（正文含摘要，保证重开面板重放后模型上下文仍是摘要）。总结器走
  `dairh_client()` 裸构造、不注册任何工具。
* **token 计量与状态栏**：面板输入框下方新增状态栏——本会话**累计 token
  （输入/输出）**与**上下文容量**实时显示，右侧为压缩按钮；provider·模型·
  工具数留在标题栏（两端都塞会挤，0.6 实测定稿此分工）。显示随每轮回复
  自动刷新；上下文占用取最近一次请求的输入 token
  （与同类面板口径一致，含系统提示/工具/全部历史）；模型上下文窗口网关一般
  不会自动告知，config.json 新增 `context_window` 字段（设置里可填，留空 =
  未知——此时只显示占用不显示百分比）。压缩重水合后的下一轮起反映压缩后
  的余量。
* **token 用量日志**：每次模型请求（含工具循环每次 round-trip、会话起标题、
  子代理、压缩总结器）追加一行 jsonl 到
  `R_user_dir("daiRH","data")/usage/usage.jsonl`（`source/model/ok/input/
  output/cache_read[/cost]`），与按请求计费网关的记账口径对齐，供外部用量
  监测工具读取对账。单一漏斗：`dairh_client()` 构造时经 ellmer 的
  `on_request_end` 回调挂上，面板/CLI/子代理全部自动覆盖，各处零改动；
  被取消的请求（tokens 全 NA）跳过不记。环境变量 `DAIRH_USAGE_LOG=0`
  整体关闭。已知边界：请求出错时 ellmer 不触发该回调（错误请求网关也不
  计费），故无失败行。
* **预设内置模型清单**：`opencode.go` / `deepseek.*` 预设新增内置模型清单——
  端点未实现 `GET /models` 时，"列出模型"按钮自动回退到该清单（点选回填，
  手填仍然可用）；切换预设会清空上一次的模型选择列表。
* **修历史抽屉搜索框图标叠字**：Bootstrap 的 `.form-control` padding 简写按
  注入顺序盖掉 shinychat 的 `padding-inline-start`，图标压在 "Search…"
  占位文字上；用更高优先级选择器把输入框留位钉死。面板布局仍为跟随
  viewer 全宽（与 0.5 一致，未设限宽）。
* **杂项**：压缩/用量均为内部实现（`R/compact.R`、`R/usage.R`），无新增导出
  函数、无新增依赖；测试基线 PASS 338。

# daiRH 0.5.0

* **show_plot 直返图片通道**：图片不再走面板总线旁路，而是作为工具结果（文本 +
  `content_image_file`）直接进入对话——shinychat 0.5 工具卡片原生内联渲染，并随
  会话历史存档重放（顺手修掉 0.4.0「绘图消息不随会话恢复」的已知边界）；支持视觉
  的模型还能真正"看到"图继续分析（openai_compatible/ollama 由 ellmer 降级回退为
  user turn 图片内容，纯文本端点只见文字，实测无害）。magick 不是硬依赖：
  未安装时（如 CI 未装）图片构造自动降级为不放缩原图（`resize="none"`），
  功能不因缺包中断。面板静态图目录与 400ms
  轮询总线整体退役。
* **钩子参数改写**：`pre_tool` 钩子新增第三种返回值 `dairh_rewrite_args(args)`——
  改写本次工具调用的参数后放行（原「字符串=拦截、NULL=放行」语义不变）；改写链
  按序组合，后续钩子与工具收到的是改写后的参数；trace 记 `args_rewritten`
  （含钩子名链），改写全程可追溯。
* **子代理委派（`delegate_task`）**：主 Agent 可把自包含子任务（批量验证、独立
  调研等跑腿活）委派给一个全新的 Chat——上下文隔离（子代理看不到主对话）、工具集
  同主体但排除委派工具自身（深度锁 1 层防递归）、独立硬预算（`subagent_max_steps`
  默认 8，父级天然消耗 1 步）、trace 带 `agent` 标记区分主/子。已知边界：委派
  同步执行，期间面板不流式回显子过程。
* **技能库（skills）**：约定目录 `R_user_dir("daiRH","data")/skills/`，放
  `<name>.md` 或 `<name>/SKILL.md` 即成为 Agent 可用的技能；`read_skill` 工具
  按需渐进加载（空参列清单、给名读全文，64KB 上限），不占常驻上下文。技能库非空
  时系统提示词自动提示模型使用；`dairh_skills_dir()` / `dairh_read_skill()` 供自检。
* **show_html（交互 HTML 进 Viewer）**：项目内 HTML（leaflet/mapview 交互地图、
  htmlwidgets 输出）经 RStudio 能力桥在 Viewer 打开，未连桥时退系统浏览器；
  html 需先保存到项目目录内（≤ 20MB）。
* **存储目录可配置**：config.json 新增 `history_dir` / `trace_dir`（留空 = 各自
  默认的用户数据 / cache 目录）；设置弹窗高级区同步新增两个路径框。改动历史目录
  后旧会话不丢，只是抽屉指向新目录。
* **杂项**：`dairh_agent_tools()` 新增 `exclude` 参数（子代理构建工具集时排除
  `delegate_task`）；子代理的工具调用改为追加进父 trace 文件（单一时间线，
  `agent` 列区分 main/sub，此前子代理写独立文件、`dairh_trace()` 只读一个，
  实测委派观测不到子过程）；`dairh_trace_path()` 不再让缓存的旧文件一票否决
  （重开面板后目录里出现更新的 trace 文件时跟随最新）；show_plot 工具内的
  图片构造带 magick 缺失降级（tryCatch 回退 resize="none"，`dairh_read_skill.Rd`
  补上漏掉的 `@param name`）；新增测试 20+ 条（钩子改写/技能库/子代理/新配置字段/
  show_plot 直返/show_html），本地基线 FAIL 0 | WARN 0 | PASS 261。

# daiRH 0.4.0

* **会话持久化（多会话历史抽屉）**：后台面板接入 shinychat 0.5 的会话存储——
  聊天区左上角时钟按钮打开抽屉，可列出 / 搜索 / 切换 / 新建 / 重命名 / 删除
  会话；重开面板自动续接最近一次会话。对话轮次（含工具调用链）经 ellmer
  record/replay 重水合进当前 Agent；治理层状态（单轮硬预算等）按新会话重新计。
  - 存储位置：`tools::R_user_dir("daiRH", "data")/conversations`（用户数据目录，
    不进项目目录）
  - 面板端口随机会让 shinychat 的浏览器令牌漂移（localStorage 按 origin 隔离），
    故固定 `scope="daiRH"`，并用官方 `_history_select` 输入通道实现自动续接
  - 新配置项：`history`（默认开）、`history_title`（LLM 看前两轮对话给会话起
    标题，默认开，关掉可省一次调用）；设置弹窗高级区同步新增两个开关
  - 「清空对话」改为"开新会话"：当前会话先存入抽屉再开新的（原先直接清掉、
    不可恢复）；gadget / CLI 模式维持原行为（不持久化）
  - 已知边界：面板主动推送的绘图消息属 UI 内容，不随会话存档恢复
* **Addins 菜单更名**：`DAILLM Chat / DAILLM Settings` → `daiRH Chat / daiRH
  Settings`（`inst/rstudio/addins.dcf`；config.json 的旧包迁移逻辑不受影响）
* **面板体验修复（本地测试反馈）**：面板页整页改 flex 布局，页面级滚动条退场
  （此前 `calc(100vh-150px)` 预留在紧凑视口下会溢出）；输入框（tiptap 编辑器）
  多行后自身滚动条不再压住发送按钮；修复"讲解选中代码"的选区自 0.2 起一直
  失效的行号 bug（`$rE` 恒为 NULL → `range$start$row`），并支持**未保存的
  无标题文档**（内容与选区直接读内存）；设置里的背景图新增"从电脑选图"
  文件选择器（副本存入 daiRH 数据目录以持久化，≤ 8MB）；面板标题右侧展示
  包 Logo（data URI 内嵌，无外链）。
* **选区讲解可靠性重构**：实测 RStudio 空闲时敲空回车不会触发主会话 later
  回调，快照式上下文可能滞留旧内容（模型会正确拒绝并提示，但用户无解）。
  新增加载项 **daiRH Send Selection**：在主会话内直接读取源码编辑器选区并
  一键直发面板（约半秒自动提交），彻底绕开快照刷新依赖；快照改用
  `getSourceEditorContext()` 优先（避免控制台焦点劫持"当前文件"语义）；
  pump 循环整体兜底防断链（快照曾因此冻结 40 分钟）。
* **杂项**：清空横幅文案修正（"聊天记录已清空"在历史模式下不再准确）；
  维护手册的单测命令改为 `testthat::test_local()`（原 `library()+test_dir()`
  实际测的是已安装旧版）

# daiRH 0.3.0

* **shinychat 0.5 / ellmer 0.5 适配**：聊天接线迁移到新版 `chat_ui()` + `chat_server()`
  （`chat_mod_ui` / `chat_mod_server`、`bookmark_on_input` / `bookmark_on_response`
  均已废弃，调用全部移除，面板不再吐 deprecation 警告）；依赖下限提到
  `ellmer (>= 0.5.0)`、`shinychat (>= 0.5.0)`。模型端工具结果仍统一为文本回传
  （ellmer 0.5 起 tool 返回复杂对象会警告，daiRH 的 9 个内置工具不受影响）。
* **面板布局自适应修复**：修复空会话时聊天区中间空一大块——shinychat 0.5 会把
  空会话问候卡用 `margin:auto` 纵向居中，并在左上角预留 30px 历史按钮区；现在
  问候卡顶部锚定、历史按钮关闭、磨砂卡片样式随自定义元素选择器失配一并找回
  （`<shiny-chat-container>` 标签选择器 + `height:100%` 撑满包盒）。已在
  360–900px 宽高区间截图验证。
* **会话持久化（多会话 history 抽屉）暂缓接入**：shinychat 0.5 自带会话存储，
  但面板的 Agent 状态（硬预算计数、工具注册、钩子）是会话级的，直接启用会
  出现"UI 回放旧对话、Agent 却是新会话"的错位；留待 harness 侧重水合方案，
  仍是路线图项。

# daiRH 0.2.0

* **harness 层落地**（H = harness 名副其实）：
  - 工具注册表：`dairh_register_tool()` / `dairh_unregister_tool()` / `dairh_list_tools()`，可覆盖内置工具
  - 钩子：`dairh_add_hook("pre_tool"/"post_tool", ...)` 拦截与改写每次工具调用
  - 单轮硬预算：`max_steps` 不再只是提示词，超出直接拦截；用户下一条消息自动重置
    （修复：ellmer 把工具结果存成 role="user" 且 @text 为空的回合，旧的回合检测会误重置预算）
  - 调用轨迹：`dairh_trace()` / `dairh_trace_path()`，jsonl 落盘（含参数/耗时/结果/拦截原因/session_reset）
  - `tools_profile`：跨进程自定义通道（后台面板子进程启动时 source）
* **面板**：新增 🧹 清空对话按钮（清聊天记录 + 重置会话与预算，不重启子进程）；
  修 `create_file` 自动建父目录；修"讲解选中代码"在快照过期时硬讲旧内容（自检提示）
* **show_plot 内置工具**（第 9 个）：agent 画完图直接渲染进聊天气泡
  （图拷入面板静态目录走同源 URL；shinychat 前端 sanitize 白名单只放行 http/https 的 img src）
* **控制台 CLI**：`dairh_cli()`，claude-code 风格启动横幅 + readline 循环 +
  ellmer 流式回显（echo="output"）；`/help` `/clear` `/tools` `/exit`
* **面板进程管理加固**：启动全程进度反馈（"正在启动…（3~15 秒）"→"已就绪（用时 X 秒）"）；
  stderr 镜像带时间戳；pid 登记文件 + `dairh_panel_stop()` 跨会话回收孤儿面板
  （仅回收命令行带 callr 脚本标记的 R 进程，不误伤）

# daiRH 0.1.0

* 首个公开版本：OpenAI 兼容端点接入 RStudio 面板；8 个内置工具
  （读/列/写/改文件、callr 子进程跑 R、R 文档、工作区摘要、编辑器上下文）；
  后台运行模式（callr 子进程 + 能力桥）；快捷任务；设置界面
