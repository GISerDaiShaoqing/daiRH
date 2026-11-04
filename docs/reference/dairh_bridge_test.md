# 自检编辑器上下文快照（诊断用）

报告快照文件的状态：是否存在、快照时间、
当时是否有已保存的活动文件。面板后台模式拿不到
编辑器内容时，用它判断快照链路的健康状态。

## Usage

``` r
dairh_bridge_test()
```

## Value

命名列表：dir / snapshot_time / base_dir / context_chars

## Examples

``` r
if (FALSE) { # \dontrun{
daiRH::dairh_bridge_test()
} # }
```
