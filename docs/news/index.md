# Changelog

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
  - 工具注册表：[`dairh_register_tool()`](https://giserdaishaoqing.github.io/daiRH/reference/dairh_register_tool.md)
    /
    [`dairh_unregister_tool()`](https://giserdaishaoqing.github.io/daiRH/reference/dairh_unregister_tool.md)
    /
    [`dairh_list_tools()`](https://giserdaishaoqing.github.io/daiRH/reference/dairh_list_tools.md)，可覆盖内置工具
  - 钩子：`dairh_add_hook("pre_tool"/"post_tool", ...)`
    拦截与改写每次工具调用
  - 单轮硬预算：`max_steps`
    不再只是提示词，超出直接拦截；用户下一条消息自动重置 （修复：ellmer
    把工具结果存成 role=“user” 且 [@text](https://github.com/text)
    为空的回合，旧的回合检测会误重置预算）
  - 调用轨迹：[`dairh_trace()`](https://giserdaishaoqing.github.io/daiRH/reference/dairh_trace.md)
    /
    [`dairh_trace_path()`](https://giserdaishaoqing.github.io/daiRH/reference/dairh_trace_path.md)，jsonl
    落盘（含参数/耗时/结果/拦截原因/session_reset）
  - `tools_profile`：跨进程自定义通道（后台面板子进程启动时 source）
- **面板**：新增 🧹 清空对话按钮（清聊天记录 +
  重置会话与预算，不重启子进程）； 修 `create_file`
  自动建父目录；修”讲解选中代码”在快照过期时硬讲旧内容（自检提示）
- **show_plot 内置工具**（第 9 个）：agent 画完图直接渲染进聊天气泡
  （图拷入面板静态目录走同源 URL；shinychat 前端 sanitize 白名单只放行
  http/https 的 img src）
- **控制台
  CLI**：[`dairh_cli()`](https://giserdaishaoqing.github.io/daiRH/reference/dairh_cli.md)，claude-code
  风格启动横幅 + readline 循环 + ellmer
  流式回显（echo=“output”）；`/help` `/clear` `/tools` `/exit`
- **面板进程管理加固**：启动全程进度反馈（“正在启动…（3~15
  秒）”→“已就绪（用时 X 秒）”）； stderr 镜像带时间戳；pid 登记文件 +
  [`dairh_panel_stop()`](https://giserdaishaoqing.github.io/daiRH/reference/dairh_panel_stop.md)
  跨会话回收孤儿面板 （仅回收命令行带 callr 脚本标记的 R 进程，不误伤）

## daiRH 0.1.0

- 首个公开版本：OpenAI 兼容端点接入 RStudio 面板；8 个内置工具
  （读/列/写/改文件、callr 子进程跑 R、R
  文档、工作区摘要、编辑器上下文）； 后台运行模式（callr 子进程 +
  能力桥）；快捷任务；设置界面
