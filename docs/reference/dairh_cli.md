# 在控制台里直接与 DaiRH Agent 对话（CLI 模式）

claude-code 风格：启动横幅（带动画）+ readline 循环 + ellmer
流式输出（工具调用过程回显）。运行在当前 R 会话（RStudio
控制台或终端），期间控制台被占用；`/exit` 退出。 硬预算/钩子/trace
与面板完全同一套 harness。

## Usage

``` r
dairh_cli(cfg = dairh_config_get())
```

## Arguments

- cfg:

  配置列表（[`dairh_config_get()`](https://gisersqdai.top/daiRH/reference/dairh_config_get.md)）

## Examples

``` r
if (FALSE) { # \dontrun{
dairh_cli()                       # 当前配置
dairh_cli(dairh_config_get())     # 同上
} # }
```
