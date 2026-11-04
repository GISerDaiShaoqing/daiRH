# 启动/复用主会话内的 RStudio 能力桥（后台面板模式）

幂等：已有存活桥时直接返回。返回共享目录路径；失败返回 ""。
主会话侧起一个 later 轮询循环处理请求文件（RStudio 空闲时会执行
later）。

## Usage

``` r
dairh_bridge_start()
```
