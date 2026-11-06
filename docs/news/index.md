# Changelog

## daiRH 0.5.0

- **show_plot
  直返图片通道**：图片不再走面板总线旁路，而是作为工具结果（文本 +
  `content_image_file`）直接进入对话——shinychat 0.5
  工具卡片原生内联渲染，并随 会话历史存档重放（顺手修掉
  0.4.0「绘图消息不随会话恢复」的已知边界）；支持视觉
  的模型还能真正”看到”图继续分析（openai_compatible/ollama 由 ellmer
  降级回退为 user turn
  图片内容，纯文本端点只见文字，实测无害）。面板静态图目录与 400ms
  轮询总线整体退役。
- **钩子参数改写**：`pre_tool` 钩子新增第三种返回值
  `dairh_rewrite_args(args)`——
  改写本次工具调用的参数后放行（原「字符串=拦截、NULL=放行」语义不变）；改写链
  按序组合，后续钩子与工具收到的是改写后的参数；trace 记
  `args_rewritten` （含钩子名链），改写全程可追溯。
- **子代理委派（`delegate_task`）**：主 Agent
  可把自包含子任务（批量验证、独立 调研等跑腿活）委派给一个全新的
  Chat——上下文隔离（子代理看不到主对话）、工具集
  同主体但排除委派工具自身（深度锁 1
  层防递归）、独立硬预算（`subagent_max_steps` 默认 8，父级天然消耗 1
  步）、trace 带 `agent` 标记区分主/子。已知边界：委派
  同步执行，期间面板不流式回显子过程。
- **技能库（skills）**：约定目录
  `R_user_dir("daiRH","data")/skills/`，放 `<name>.md` 或
  `<name>/SKILL.md` 即成为 Agent 可用的技能；`read_skill` 工具
  按需渐进加载（空参列清单、给名读全文，64KB
  上限），不占常驻上下文。技能库非空
  时系统提示词自动提示模型使用；[`dairh_skills_dir()`](https://gisersqdai.top/daiRH/reference/dairh_skills_dir.md)
  /
  [`dairh_read_skill()`](https://gisersqdai.top/daiRH/reference/dairh_read_skill.md)
  供自检。
- **show_html（交互 HTML 进 Viewer）**：项目内 HTML（leaflet/mapview
  交互地图、 htmlwidgets 输出）经 RStudio 能力桥在 Viewer
  打开，未连桥时退系统浏览器； html 需先保存到项目目录内（≤ 20MB）。
- **存储目录可配置**：config.json 新增 `history_dir` / `trace_dir`（留空
  = 各自 默认的用户数据 / cache
  目录）；设置弹窗高级区同步新增两个路径框。改动历史目录
  后旧会话不丢，只是抽屉指向新目录。
- **杂项**：[`dairh_agent_tools()`](https://gisersqdai.top/daiRH/reference/dairh_agent_tools.md)
  新增 `exclude` 参数（子代理构建工具集时排除
  `delegate_task`）；新增测试 20+
  条（钩子改写/技能库/子代理/新配置字段/show_plot
  直返/show_html），本地基线 FAIL 0 \| WARN 0 \| PASS 254。

## daiRH 0.4.0

- **会话持久化（多会话历史抽屉）**：后台面板接入 shinychat 0.5
  的会话存储—— 聊天区左上角时钟按钮打开抽屉，可列出 / 搜索 / 切换 / 新建
  / 重命名 / 删除
  会话；重开面板自动续接最近一次会话。对话轮次（含工具调用链）经 ellmer
  record/replay 重水合进当前
  Agent；治理层状态（单轮硬预算等）按新会话重新计。
  - 存储位置：`tools::R_user_dir("daiRH", "data")/conversations`（用户数据目录，
    不进项目目录）
  - 面板端口随机会让 shinychat 的浏览器令牌漂移（localStorage 按 origin
    隔离）， 故固定 `scope="daiRH"`，并用官方 `_history_select`
    输入通道实现自动续接
  - 新配置项：`history`（默认开）、`history_title`（LLM
    看前两轮对话给会话起
    标题，默认开，关掉可省一次调用）；设置弹窗高级区同步新增两个开关
  - 「清空对话」改为”开新会话”：当前会话先存入抽屉再开新的（原先直接清掉、
    不可恢复）；gadget / CLI 模式维持原行为（不持久化）
  - 已知边界：面板主动推送的绘图消息属 UI 内容，不随会话存档恢复
- **Addins 菜单更名**：`DAILLM Chat / DAILLM Settings` →
  `daiRH Chat / daiRH Settings`（`inst/rstudio/addins.dcf`；config.json
  的旧包迁移逻辑不受影响）
- **面板体验修复（本地测试反馈）**：面板页整页改 flex
  布局，页面级滚动条退场 （此前 `calc(100vh-150px)`
  预留在紧凑视口下会溢出）；输入框（tiptap 编辑器）
  多行后自身滚动条不再压住发送按钮；修复”讲解选中代码”的选区自 0.2
  起一直 失效的行号 bug（`$rE` 恒为 NULL →
  `range$start$row`），并支持**未保存的
  无标题文档**（内容与选区直接读内存）；设置里的背景图新增”从电脑选图”
  文件选择器（副本存入 daiRH 数据目录以持久化，≤ 8MB）；面板标题右侧展示
  包 Logo（data URI 内嵌，无外链）。
- **选区讲解可靠性重构**：实测 RStudio 空闲时敲空回车不会触发主会话
  later
  回调，快照式上下文可能滞留旧内容（模型会正确拒绝并提示，但用户无解）。
  新增加载项 **daiRH Send
  Selection**：在主会话内直接读取源码编辑器选区并
  一键直发面板（约半秒自动提交），彻底绕开快照刷新依赖；快照改用
  `getSourceEditorContext()` 优先（避免控制台焦点劫持”当前文件”语义）；
  pump 循环整体兜底防断链（快照曾因此冻结 40 分钟）。
- **杂项**：清空横幅文案修正（“聊天记录已清空”在历史模式下不再准确）；
  维护手册的单测命令改为
  [`testthat::test_local()`](https://testthat.r-lib.org/reference/test_package.html)（原
  `library()+test_dir()` 实际测的是已安装旧版）

## daiRH 0.3.0

- **shinychat 0.5 / ellmer 0.5 适配**：聊天接线迁移到新版 `chat_ui()` +
  `chat_server()` （`chat_mod_ui` /
  `chat_mod_server`、`bookmark_on_input` / `bookmark_on_response`
  均已废弃，调用全部移除，面板不再吐 deprecation 警告）；依赖下限提到
  `ellmer (>= 0.5.0)`、`shinychat (>= 0.5.0)`。模型端工具结果仍统一为文本回传
  （ellmer 0.5 起 tool 返回复杂对象会警告，daiRH 的 9
  个内置工具不受影响）。
- **面板布局自适应修复**：修复空会话时聊天区中间空一大块——shinychat 0.5
  会把 空会话问候卡用 `margin:auto` 纵向居中，并在左上角预留 30px
  历史按钮区；现在
  问候卡顶部锚定、历史按钮关闭、磨砂卡片样式随自定义元素选择器失配一并找回
  （`<shiny-chat-container>` 标签选择器 + `height:100%` 撑满包盒）。已在
  360–900px 宽高区间截图验证。
- **会话持久化（多会话 history 抽屉）暂缓接入**：shinychat 0.5
  自带会话存储， 但面板的 Agent
  状态（硬预算计数、工具注册、钩子）是会话级的，直接启用会 出现”UI
  回放旧对话、Agent 却是新会话”的错位；留待 harness 侧重水合方案，
  仍是路线图项。

## daiRH 0.2.0

- **harness 层落地**（H = harness 名副其实）：
  - 工具注册表：[`dairh_register_tool()`](https://gisersqdai.top/daiRH/reference/dairh_register_tool.md)
    /
    [`dairh_unregister_tool()`](https://gisersqdai.top/daiRH/reference/dairh_unregister_tool.md)
    /
    [`dairh_list_tools()`](https://gisersqdai.top/daiRH/reference/dairh_list_tools.md)，可覆盖内置工具
  - 钩子：`dairh_add_hook("pre_tool"/"post_tool", ...)`
    拦截与改写每次工具调用
  - 单轮硬预算：`max_steps`
    不再只是提示词，超出直接拦截；用户下一条消息自动重置 （修复：ellmer
    把工具结果存成 role=“user” 且 [@text](https://github.com/text)
    为空的回合，旧的回合检测会误重置预算）
  - 调用轨迹：[`dairh_trace()`](https://gisersqdai.top/daiRH/reference/dairh_trace.md)
    /
    [`dairh_trace_path()`](https://gisersqdai.top/daiRH/reference/dairh_trace_path.md)，jsonl
    落盘（含参数/耗时/结果/拦截原因/session_reset）
  - `tools_profile`：跨进程自定义通道（后台面板子进程启动时 source）
- **面板**：新增 🧹 清空对话按钮（清聊天记录 +
  重置会话与预算，不重启子进程）； 修 `create_file`
  自动建父目录；修”讲解选中代码”在快照过期时硬讲旧内容（自检提示）
- **show_plot 内置工具**（第 9 个）：agent 画完图直接渲染进聊天气泡
  （图拷入面板静态目录走同源 URL；shinychat 前端 sanitize 白名单只放行
  http/https 的 img src）
- **控制台
  CLI**：[`dairh_cli()`](https://gisersqdai.top/daiRH/reference/dairh_cli.md)，claude-code
  风格启动横幅 + readline 循环 + ellmer
  流式回显（echo=“output”）；`/help` `/clear` `/tools` `/exit`
- **面板进程管理加固**：启动全程进度反馈（“正在启动…（3~15
  秒）”→“已就绪（用时 X 秒）”）； stderr 镜像带时间戳；pid 登记文件 +
  [`dairh_panel_stop()`](https://gisersqdai.top/daiRH/reference/dairh_panel_stop.md)
  跨会话回收孤儿面板 （仅回收命令行带 callr 脚本标记的 R 进程，不误伤）

## daiRH 0.1.0

- 首个公开版本：OpenAI 兼容端点接入 RStudio 面板；8 个内置工具
  （读/列/写/改文件、callr 子进程跑 R、R
  文档、工作区摘要、编辑器上下文）； 后台运行模式（callr 子进程 +
  能力桥）；快捷任务；设置界面
