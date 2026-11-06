# 技能库目录

返回技能库目录路径（不存在则创建）。目录约定见
[`dairh_read_skill()`](https://gisersqdai.top/daiRH/reference/dairh_read_skill.md)：
每个 `<name>.md` 或 `<name>/SKILL.md` 是一个技能，Agent 可通过
read_skill 工具列出并按名读取。测试可用 option `daiRH.skills_dir` 覆盖。

## Usage

``` r
dairh_skills_dir()
```

## Value

目录路径（字符向量，长度 1）
