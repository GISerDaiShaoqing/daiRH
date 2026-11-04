# 快捷任务提示词

根据任务类型生成发给模型的用户消息模板。

## Usage

``` r
dairh_quick_prompt(
  kind = c("explain", "explain_selection", "review", "docs"),
  detail = NULL
)
```

## Arguments

- kind:

  任务类型：

  explain

  :   解释当前文件

  explain_selection

  :   只讲解选中的代码

  review

  :   代码审查/重构建议

  docs

  :   R 文档问答

- detail:

  用户的补充要求或问题（可选）

## Value

单个字符串
