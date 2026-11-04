# 创建一个带工具的 DaiRH Agent 会话

构建按配置连接的 Chat 客户端，注入系统提示并注册工具集。 注册前会先执行
`cfg$tools_profile` 指向的 R 脚本（注册自定义工具/钩子的
跨进程通道）；工具集经 harness 层包装，并把 Chat 对象回填给
会话状态（供硬预算的回合检测使用）。

## Usage

``` r
dairh_new_agent(cfg = dairh_config_get())
```

## Arguments

- cfg:

  配置列表（[`dairh_config_get()`](https://giserdaishaoqing.github.io/daiRH/reference/dairh_config_get.md)）

## Value

ellmer Chat 对象（可交给 shinychat 聊天模块）
