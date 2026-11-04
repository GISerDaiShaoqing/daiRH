# 当前打开文件 / 选区上下文（文本）

生成给 LLM 看的上下文摘要：文件路径与内容（截断）、选区文本与行号。 不在
RStudio 中时返回提示文本。

## Usage

``` r
dairh_editor_context_text(max_lines = 160)
```

## Arguments

- max_lines:

  文件内容最多注入的行数

## Value

单个字符串（markdown/纯文本块）
