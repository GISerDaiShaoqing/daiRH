# 读取 DaiRH 配置

读取持久化配置并合并默认值；配置文件缺失或损坏时自动回退默认值。

## Usage

``` r
dairh_config_get()
```

## Value

命名列表，包含 provider/base_url/model/api_key 等字段。
