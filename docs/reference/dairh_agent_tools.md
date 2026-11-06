# 构建 DaiRH Agent 的全部工具

依据配置决定注册哪些工具：allow_edit 控制 create_file/edit_file，
allow_run 控制 run_r_code；返回 ellmer tool 对象列表（未注册到会话）。
每个工具都会经 [harness
层](https://gisersqdai.top/daiRH/reference/dairh_register_tool.md)
包装（钩子/硬预算/trace）， 并合并
[`dairh_register_tool()`](https://gisersqdai.top/daiRH/reference/dairh_register_tool.md)
注册的自定义工具。

## Usage

``` r
dairh_agent_tools(
  cfg = dairh_config_get(),
  state = .dairh_new_state(cfg),
  exclude = character(0)
)
```

## Arguments

- cfg:

  [`dairh_config_get()`](https://gisersqdai.top/daiRH/reference/dairh_config_get.md)
  的配置列表

- state:

  harness 会话状态（一般由
  [`dairh_new_agent()`](https://gisersqdai.top/daiRH/reference/dairh_new_agent.md)
  创建并持有； 直接调用本函数时自动新建）

- exclude:

  从最终工具集里排除的工具名（子代理构建时用它 排除 delegate_task
  自身，防递归；一般用不到）

## Value

命名列表；每个元素是 ellmer Tool 对象（可用 `chat$register_tool()`
注册）； 附属属性 `.dairh_state` 是对应的状态环境
