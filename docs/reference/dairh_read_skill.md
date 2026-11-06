# 查看技能库清单

等价于 Agent 的 read_skill 工具留空调用：列出技能库里当前可用的技能名与
首行简介。适合配置完技能后快速自检。

## Usage

``` r
dairh_read_skill(name = "")
```

## Arguments

- name:

  技能名；留空则列出技能清单，给名读取全文

## Value

技能说明文本（字符向量，长度 1）
