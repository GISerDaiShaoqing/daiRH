# 构造 pre_tool 钩子的参数改写返回值

在 `pre_tool`
钩子里返回本对象（而不是字符串/NULL），即可\*\*改写\*\*本次工具调用的
参数：后续钩子与工具本身收到的都是改写后的参数，改写动作记入 trace
（`args_rewritten` 字段，含钩子名链）。字符串 = 拦截、NULL =
放行的原语义不变。

## Usage

``` r
dairh_rewrite_args(args)
```

## Arguments

- args:

  改写后的参数（命名列表，键与工具形参一致；整包替换，不做深合并）

## Value

带标记的改写对象（仅作为 pre_tool 钩子的返回值使用）

## Examples

``` r
if (FALSE) { # \dontrun{
# 给 run_r_code 的调用统一收紧超时（参数改写示例）
dairh_add_hook("pre_tool", function(name, args) {
  if (identical(name, "run_r_code") && is.character(args$code)) {
    dairh_rewrite_args(list(code = args$code, timeout_sec = 120))
  }
})
} # }
```
