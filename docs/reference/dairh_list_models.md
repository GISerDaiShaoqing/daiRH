# 列出当前端点可用的模型

Ollama 走 `/api/tags`，OpenAI 兼容端点走 `GET /models`。 请求失败时返回
character(0)（不报错，UI 可显示空列表）。

## Usage

``` r
dairh_list_models(cfg = dairh_config_get(), timeout_s = 10)
```

## Arguments

- cfg:

  配置对象（dairh_config_get() 的结果或同构字段的 list）。

- timeout_s:

  请求超时秒数，默认 10。

## Value

模型名的 character 向量；请求失败时为 character(0)。
