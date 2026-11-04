# Package index

## 启动与入口

面板、设置 Addin 与 claude-code 风格的控制台 CLI 的入口函数。

- [`dairh_app()`](https://gisersqdai.top/daiRH/reference/dairh_app.md) :
  构建面板（ui + server）
- [`dairh_addin_chat()`](https://gisersqdai.top/daiRH/reference/dairh_addin_chat.md)
  : 打开 DaiRH 聊天助手面板（RStudio Addin）
- [`dairh_addin_settings()`](https://gisersqdai.top/daiRH/reference/dairh_addin_settings.md)
  : 打开 DaiRH 设置对话框（RStudio Addin）
- [`dairh_cli()`](https://gisersqdai.top/daiRH/reference/dairh_cli.md) :
  在控制台里直接与 DaiRH Agent 对话（CLI 模式）
- [`dairh_quick_prompt()`](https://gisersqdai.top/daiRH/reference/dairh_quick_prompt.md)
  : 快捷任务提示词

## Agent 与会话

组装 Agent：构建对话客户端、注册内置工具、生成系统提示词。

- [`dairh_new_agent()`](https://gisersqdai.top/daiRH/reference/dairh_new_agent.md)
  : 创建一个带工具的 DaiRH Agent 会话
- [`dairh_agent_tools()`](https://gisersqdai.top/daiRH/reference/dairh_agent_tools.md)
  : 构建 DaiRH Agent 的全部工具
- [`dairh_client()`](https://gisersqdai.top/daiRH/reference/dairh_client.md)
  : 按配置构建 ellmer Chat 对象
- [`dairh_list_models()`](https://gisersqdai.top/daiRH/reference/dairh_list_models.md)
  : 列出当前端点可用的模型

## 配置与端点

配置持久化、模型列表自动发现、RStudio 上下文与面板能力桥诊断。

- [`dairh_config_get()`](https://gisersqdai.top/daiRH/reference/dairh_config_get.md)
  : 读取 DaiRH 配置
- [`dairh_config_set()`](https://gisersqdai.top/daiRH/reference/dairh_config_set.md)
  : 写入 DaiRH 配置
- [`dairh_bridge_test()`](https://gisersqdai.top/daiRH/reference/dairh_bridge_test.md)
  : 自检编辑器上下文快照（诊断用）
- [`dairh_editor_context_text()`](https://gisersqdai.top/daiRH/reference/dairh_editor_context_text.md)
  : 当前打开文件 / 选区上下文（文本）

## harness：自定义工具与钩子

把项目特有的能力教给 Agent；pre/post 钩子拦截或改写每次工具调用。

- [`dairh_register_tool()`](https://gisersqdai.top/daiRH/reference/dairh_register_tool.md)
  : 注册自定义工具（扩展 Agent 能力）
- [`dairh_unregister_tool()`](https://gisersqdai.top/daiRH/reference/dairh_unregister_tool.md)
  : 注销已注册的自定义工具
- [`dairh_list_tools()`](https://gisersqdai.top/daiRH/reference/dairh_list_tools.md)
  : 列出当前可用的工具
- [`dairh_add_hook()`](https://gisersqdai.top/daiRH/reference/dairh_add_hook.md)
  : 添加 Agent 钩子（工具调用拦截/改写）
- [`dairh_remove_hook()`](https://gisersqdai.top/daiRH/reference/dairh_remove_hook.md)
  : 移除钩子

## 调用轨迹（trace）

每次工具调用的参数、耗时、结果摘要与拦截原因，jsonl 落盘可回放。

- [`dairh_trace()`](https://gisersqdai.top/daiRH/reference/dairh_trace.md)
  : 查看最近的工具调用轨迹
- [`dairh_trace_path()`](https://gisersqdai.top/daiRH/reference/dairh_trace_path.md)
  : 当前/最近一个 Agent 的 trace 文件路径

## 面板进程管理

后台模式的面板跑在独立子进程里；这两个函数负责重启与孤儿回收。

- [`dairh_panel_restart()`](https://gisersqdai.top/daiRH/reference/dairh_panel_restart.md)
  : 重启后台运行的 DaiRH 面板
- [`dairh_panel_stop()`](https://gisersqdai.top/daiRH/reference/dairh_panel_stop.md)
  : 关闭后台运行的 DaiRH 面板

## 内部辅助（未导出）

文档化但没有导出的内部函数；了解面板协议与系统提示词拼装时有用。

- [`dairh_base_dir()`](https://gisersqdai.top/daiRH/reference/dairh_base_dir.md)
  : 当前基础目录（安全边界）
- [`dairh_bridge_start()`](https://gisersqdai.top/daiRH/reference/dairh_bridge_start.md)
  : 启动/复用主会话内的 RStudio 能力桥（后台面板模式）
- [`dairh_panel_ui()`](https://gisersqdai.top/daiRH/reference/dairh_panel_ui.md)
  : 构建面板 UI
- [`dairh_system_prompt()`](https://gisersqdai.top/daiRH/reference/dairh_system_prompt.md)
  : DaiRH 系统提示词
