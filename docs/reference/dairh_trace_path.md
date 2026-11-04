# 当前/最近一个 Agent 的 trace 文件路径

返回本进程最近一次写入的 trace jsonl 文件路径； 若本进程还没写过，回退到
trace 目录里最新的一个文件。

## Usage

``` r
dairh_trace_path()
```

## Value

文件路径字符串，没有则 NULL
