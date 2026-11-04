# 构建面板（ui + server）

返回 `list(ui=, server=)`，可直接交给
[`shiny::runGadget()`](https://rdrr.io/pkg/shiny/man/runGadget.html)，
addin 内部也是这么用的。

## Usage

``` r
dairh_app(cfg = dairh_config_get())
```

## Arguments

- cfg:

  配置列表（[`dairh_config_get()`](https://gisersqdai.top/daiRH/reference/dairh_config_get.md)）

## Value

命名列表
`list(ui = <shiny \页\面\对\象>, server = function(input, output, session))`

## Examples

``` r
if (FALSE) { # \dontrun{
app <- dairh_app()
shiny::runGadget(app$ui, app$server, viewer = shiny::paneViewer(500))
} # }
```
