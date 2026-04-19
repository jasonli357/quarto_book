# 创建与使用 stata-data-cleaner Skill {#sec-skill-demo}

本章详细介绍 `stata-data-cleaner` Skill 的创建过程、工作原理和使用方法。

## 为什么要创建数据处理 Skill

对于经常使用 Stata 进行实证研究的经管类研究者而言，创建一个专门的数据处理 Skill 可以：

- 向 AI 说明数据处理的具体要求（例如剔除哪些样本）
- 给 AI 制定工作规范（例如变量标签怎么写、最后输出什么文件）
- 避免每次都重复说明"剔除 ST 股、剔除金融业、指标要缩尾"等常规操作
- 
## 创建 Skill

### prompt

在 plan mode 下输入以下 prompt，让 AI 根据已有的数据处理经验创建 Skill：

```
现在 data/raw/ 里面的数据清洗完了。请你把清洗数据的流程打包成一个
skill，放在当前项目文件夹。参考之前的清洗流程和清洗代码，让 skill
实现以下功能：

1. 自己探索数据结构（尽可能快速，不要扫描整个大型数据集）
2. 全面检查数据预处理操作（保留合并报表、保留年度数据、统一变量名、
   字符型转数值型、剔除金融行业、剔除 ST 样本、剔除异常值、去重、
   缩尾等）是否需要进行
3. 尤其关注缺失值的情况
4. 如果不确定某个操作是否需要进行，要向我提问
5. 根据需求判断是处理单个数据集还是合并多个数据集
6. 根据需求保留和计算需要的变量
7. 清洗完成后进行描述性统计

最终输出：.do 文档、.dta 文件、数据处理工作小结 .md 文档

用 stata mcp 调用 stata，不要用命令行调用。
因为每次处理的数据结构可能不一样，考虑到的情况要尽可能全面。
```

### 创建过程

AI 会分析之前的清洗代码和工作小结，提炼出通用的数据处理流程，然后生成：

- `SKILL.md`：核心定义文件，包含元数据和 5 阶段工作流
- `references/operations-guide.md`：详细操作参考手册

创建过程约 7 分钟。

## 生成的 Skill 结构

```
.claude/skills/stata-data-cleaner/
├── SKILL.md                    # 核心文件
└── references/
    └── operations-guide.md     # 操作参考手册
```

## 5 阶段工作流内容

> 这部分是 AI 生成的总结。关于 skill 规定的 5 阶段工作流具体内容，可查看`.claude\skills\stata-data-cleaner`

### Phase 1：Explore — 探索数据结构

目标：快速了解数据，**不导入整个大数据集**（有些文件超过 300 MB）。

**步骤：**

1. **扫描数据目录** — 列出所有文件和子目录，识别文件格式和目录结构
2. **读取说明文件**（最快途径） — CSMAR 数据有 `[DES][csv].txt` 文件，包含完整的变量定义
3. **用 Stata 确认** — 导入少量样本行确认文档描述

```stata
import delimited "C:/path/file.csv", clear rowfirst(2) ///
    encoding("utf8") bindquote(strict)
describe
list in 1/3
```

**关键确认事项：**

- 变量名在 Stata 中会被 `import delimited` **全部小写化**
- 金额是否以字符串存储
- 日期格式和标识符格式

### Phase 2：Diagnose — 诊断数据质量问题

对每个数据集进行针对性检查：

| 检查项 | 方法 | 关注点 |
|--------|------|--------|
| 重复记录 | `duplicates report` | 是否有多种报表类型或重述报告 |
| 缺失值 | `misstable summarize` | 缺失率 >10% 的变量需报告给用户 |
| 类型问题 | `describe` | 数值是否被存储为字符串 |
| 报表类型分布 | `tab typrep` | 合并 vs 母公司报表比例 |
| 行业分布 | `tab substr(industrycode,1,1)` | 金融业占比 |
| 特殊情况 | `count if strpos(shortname,"ST")` | ST 股、负资产、极端值 |

**缺失值的关键分析：**

- **合并风险**：数据集 A 的变量 X 有 5% 缺失，数据集 B 的变量 Y 有 8% 缺失，合并后至少有一个缺失的比例可能达到 13%
- **计算风险**：ROA = 净利润 / 总资产，如果净利润有高缺失率，计算出的 ROA 缺失率会更高

### Phase 3：Consult — 向用户确认

只询问**真正不确定**的事情。如果数据中没有 ST 股票，就不需要问是否要剔除。

**必问项：**

1. 需要计算哪些变量？—— 用户的研究问题决定一切
2. 需要合并哪些数据集？—— 确认合并键

**条件性询问**（仅当数据中存在该问题时才问）：

3. 是否剔除金融行业？（默认：是）
4. 是否剔除 ST 股票？（默认：是）
5. 缩尾比例？（默认：1%/99%）
6. 时间范围？
7. 年度还是季度？

::: callout-tip
## 合并前必须告知

在执行合并前，Skill 会向用户报告每个数据集的观测数和预计匹配率，以及可能丢失的观测数量。例如："资产负债表有 43,292 条年报，利润表有 43,292 条。合并后预计匹配约 43,000 条。"
:::

### Phase 4：Execute — 生成并执行代码

Skill 会生成一个结构化的 `.do` 文件：

```stata
* ============================================================
* [描述处理目的]
* ============================================================
clear all
set more off

* --- 1. 导入数据 ---
* --- 2. 变量准备 ---     (rename, destring, 日期提取)
* --- 3. 筛选 ---         (报表类型、时间范围、行业)
* --- 4. 去重 ---
* --- 5. 合并 ---         (含 _merge 诊断)
* --- 6. 样本筛选 ---     (金融、ST、负资产等)
* --- 7. 变量计算 ---
* --- 8. 缺失值处理 ---
* --- 9. 缩尾 ---
* --- 10. 变量标签 ---
* --- 11. 描述性统计 ---
* --- 12. 保存 ---
```

如果执行出错，Skill 会读取错误信息、修复代码并重新执行，不会盲目重试。

### Phase 5：Document — 输出与文档

| 输出 | 位置 | 说明 |
|------|------|------|
| `.do` 文件 | `code/` | 完整的、带注释的 Stata 代码 |
| `.dta` 文件 | `data/processed/` | 清洗后的数据集 |
| `.md` 文件 | `file/` | 处理报告（操作记录 + 描述性统计） |

## 关键 Stata 代码模式

Skill 中内置了以下常用模式：

**导入 CSV（处理 CSMAR 编码和引号）：**

```stata
import delimited "C:/path/file.csv", clear encoding("utf8") bindquote(strict)
```

**从日期字符串提取年份：**

```stata
gen year = real(substr(datevar, 1, 4))
```

**筛选年度 + 合并报表（CSMAR 惯例）：**

```stata
keep if substr(accper, 6, 2) == "12" & typrep == "A"
```

**不依赖外部包的缩尾：**

```stata
foreach var of varlist var1 var2 var3 {
    _pctile `var', percentiles(1 99)
    local p1 = r(r1)
    local p99 = r(r2)
    replace `var' = `p1' if `var' < `p1' & !missing(`var')
    replace `var' = `p99' if `var' > `p99' & !missing(`var')
}
```

**计算增长率（安全版本）：**

```stata
sort stkcd year
by stkcd: gen growth = (revenue - revenue[_n-1]) ///
    / abs(revenue[_n-1]) if _n > 1 & revenue[_n-1] != 0
```

注意使用 `abs()` 和 `!= 0` 检查来处理基期为负值或零的情况。

**带诊断的合并：**

```stata
merge 1:1 stkcd year using `other'
tab _merge
drop if _merge != 3
drop _merge
```

## 常见陷阱与排错

| 陷阱 | 原因 | 解决方法 |
|------|------|----------|
| 变量名找不到 | `import delimited` 会将所有变量名**小写化** | 代码中统一使用小写变量名 |
| CSV 导入引号错误 | CSMAR 的值被双引号包裹 | 使用 `bindquote(strict)` |
| 空字符串 ≠ 缺失值 | CSMAR 用空 `""` 表示缺失，导入后是空字符串不是 Stata 缺失值 | 对数值列执行 `destring, replace force` |
| 路径错误 | Stata MCP 运行在 Windows 端 | 始终使用 `C:/Users/...`，不用 `/mnt/c/...` |
| 内存不足 | 资产负债表可达 300+ MB | 先筛选（保留年度+合并报表）再处理 |
| 增长率分母为零 | 上期营收为零或负值 | 使用 `abs()` 并添加 `!= 0` 检查 |
| 合并键类型不匹配 | 一边是字符串，一边是数值 | 合并前确保两边类型一致 |

## 使用 Skill 清洗数据

创建完成后，使用这个 Skill 清洗数据的流程非常简单：

1. 将原始数据放入 `data/raw/`
2. 在 Claude Code 中描述你的需求（例如"清洗这些数据并计算 Size、ROA"）
3. Skill 自动触发，执行 5 阶段工作流
4. 在 Phase 3 确认 Skill 提出的问题
5. 等待执行完成，查看输出文件
