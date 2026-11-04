# 按配置构建 ellmer Chat 对象

provider = "ollama" 时使用
[ellmer::chat_ollama](https://ellmer.tidyverse.org/reference/chat_ollama.html)，
provider = "openai_compatible" 时使用
[ellmer::chat_openai_compatible](https://ellmer.tidyverse.org/reference/chat_openai_compatible.html)
（DeepSeek / GLM / Kimi / 任意 OpenAI 兼容网关均可）。
这里只构造客户端，不发网络请求。

## Usage

``` r
dairh_client(cfg = dairh_config_get(), system_prompt = NULL)
```

## Arguments

- cfg:

  [`dairh_config_get()`](https://giserdaishaoqing.github.io/daiRH/reference/dairh_config_get.md)
  的配置列表

- system_prompt:

  覆盖系统提示词；NULL 则不附系统提示

## Value

ellmer Chat (R6) 对象
