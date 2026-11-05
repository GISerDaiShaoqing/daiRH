# 重启后台运行的 DaiRH 面板

停所有面板子进程，并按当前配置重新打开（后台模式 会自动重开
Viewer）。给面板长时间不响应、子进程意外退出或
只想换发全新会话时用，相当于"panel_stop + 直接再打开"。
会话历史不再丢失：抽屉存储在用户数据目录（cfg\$history 开启时），
重启后重新打开面板会自动续接最近一次会话。

## Usage

``` r
dairh_panel_restart()
```

## Value

隐式返回新启动的面板子进程句枰

## Examples

``` r
if (FALSE) { # \dontrun{
dairh_panel_restart()
} # }
```
