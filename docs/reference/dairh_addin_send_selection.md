# 把选中的代码一键发送到 DaiRH 面板（RStudio Addin）

在主会话内直接读取源码编辑器的当前选区（不走快照、不依赖控制台活动），
组装讲解提示词后经桥通道直发，后台面板会在约半秒内自动提交给模型。
推荐在 Tools → Modify Keyboard Shortcuts 里给本加载项绑一个快捷键，
之后"选中代码 → 按快捷键"即可。

## Usage

``` r
dairh_addin_send_selection()
```

## Examples

``` r
if (FALSE) { # \dontrun{
dairh_addin_send_selection()
} # }
```
