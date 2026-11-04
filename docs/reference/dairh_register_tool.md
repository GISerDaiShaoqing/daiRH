# 注册自定义工具（扩展 Agent 能力）

把一个 R 函数注册为 Agent 可调用的工具；下一次打开面板 （或同进程内再次
[`dairh_new_agent()`](https://gisersqdai.top/daiRH/reference/dairh_new_agent.md)
时生效）。与内置工具同名可覆盖 （需
`overwrite = TRUE`），可用来替换默认行为。

## Usage

``` r
dairh_register_tool(
  name,
  fn,
  description,
  arguments = list(),
  overwrite = FALSE
)
```

## Arguments

- name:

  工具名（字母开头，仅字母/数字/`_ - .`，≤ 64 字符）

- fn:

  工具函数，返回字符串结果（非字符串会被
  [`str()`](https://rdrr.io/r/utils/str.html) 摘要化）； 形参必须与
  `arguments` 一一对应

- description:

  给模型看的工具说明（写清楚什么时候该用、返回什么）

- arguments:

  命名列表，值为 `ellmer::type_*()` 类型定义

- overwrite:

  同名工具（含内置）已存在时是否覆盖

## Value

不可见地返回工具名

## Details

**后台模式注意**：面板跑在独立子进程，主会话的注册对它不可见。
请把注册代码写进一个 R 脚本，在设置里把 `tools_profile` 指向它，
面板启动时会自动
source（同一进程同一文件只执行一次，改动后重开面板生效）。

## Examples

``` r
if (FALSE) { # \dontrun{
dairh_register_tool(
  "load_my_data",
  function(path) paste0("OK: 已加载 ", path),
  "读取项目里的标准数据文件并返回结构摘要。",
  arguments = list(path = ellmer::type_string("数据文件路径", required = TRUE))
)
} # }
```
