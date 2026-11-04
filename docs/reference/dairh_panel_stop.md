# 关闭后台运行的 DaiRH 面板

杀掉后台模式启动的所有面板子进程，并停掉主会话内的 RStudio
能力桥。一般直接关掉面板标签页就够了（最后一个
页面关闭后子进程在数秒宽限内自动退出）；这个函数用于
事后清理残留进程或强制结束会话。控制台 Restart R 后句柄
失效时，本函数还会按启动时的 pid 登记文件扫描回收跨会话孤儿
面板子进程（仅杀命令行带 callr 脚本标记的 R 进程，不误伤其它进程）。
经典模式（gadget）无需调用。

## Usage

``` r
dairh_panel_stop()
```

## Value

隐式返回无值

## Examples

``` r
if (FALSE) { # \dontrun{
dairh_panel_stop()
} # }
```
