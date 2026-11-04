# 查看最近的工具调用轨迹

读取最近一个 agent 的 trace jsonl 尾部，返回 data.frame。
每次工具调用（含参数、耗时、结果摘要、是否被拦截）都会留痕。

## Usage

``` r
dairh_trace(n = 20)
```

## Arguments

- n:

  取最后 n 条记录

## Value

data.frame（ts / type / tool / duration_s / ok / result / veto ...
按行为一次事件）
