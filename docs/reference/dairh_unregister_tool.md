# 注销已注册的自定义工具

只能移除
[`dairh_register_tool()`](https://gisersqdai.top/daiRH/reference/dairh_register_tool.md)
注册的工具；内置工具不可注销 （可用同名注册覆盖）。

## Usage

``` r
dairh_unregister_tool(name)
```

## Arguments

- name:

  工具名

## Value

不可见 TRUE；名字不存在时 FALSE
