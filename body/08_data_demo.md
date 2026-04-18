# 实战演示：清洗 CSMAR 企业财务数据 {#sec-data-demo}

本章通过一个完整的实战案例，演示如何使用 Claude Code 清洗 CSMAR（国泰安）企业财务数据，计算常用的公司特征变量。

## 任务说明

**目标**：从企业基本信息和财务报表数据中，计算 5 个企业特征变量：

| 变量 | 含义 | 计算公式 |
|------|------|----------|
| Size | 公司规模 | ln(总资产) |
| Age | 公司年龄 | 当年年份 - 上市年份 |
| Lev | 资产负债率 | 负债合计 / 资产总计 |
| Growth | 营业收入增长率 | (本期营收 - 上期营收) / \|上期营收\| |
| ROA | 资产收益率 | 净利润 / 资产总计 |

**额外要求**：

- 删除金融行业（行业代码 J 开头）
- 计算出的指标需进行缩尾处理
- 输出：`.do` 文件、`.dta` 数据集、`.md` 工作小结

## 数据概况

本次使用的数据来自 CSMAR 数据库，包含 4 个数据集：

| 数据集 | 文件名 | 主要内容 |
|--------|--------|----------|
| 资产负债表 | `FS_Combas.csv` | 资产、负债、所有者权益等 154 个变量 |
| 利润表 | `FS_Comins.csv` | 营业收入、净利润等 80 个变量 |
| 现金流量表（间接法） | `FS_Comscfi.csv` | 经营/投资/筹资现金流等 27 个变量 |
| 上市公司基本信息年度表 | `STK_LISTEDCOINFOANL.csv` | 股票代码、行业分类、上市日期等 |

每个数据集都附有 `[DES][csv].txt` 说明文件，包含完整的变量定义。

## 探索阶段

在 plan mode 下输入任务需求后，AI 首先会探索数据结构。

### 关键发现

AI 通过读取说明文件和导入样本行，发现了以下关键信息：

**1. 变量名不统一**

不同数据集使用不同的变量名来表示相同的概念：

- 股票代码：基本信息表用 `Symbol`，其他表用 `Stkcd`
- 报告期：现金流量表用 `EndDate`，其他表用 `Accper`

**2. 金额以字符串存储**

CSMAR 的 CSV 文件中，金额类字段以字符串格式存储（如 `"19802000000.00"`），Stata 导入后需要通过 `destring` 转为数值型。

**3. 报表类型区分**

每家公司同时有合并报表（`Typrep = "A"`）和母公司报表（`Typrep = "B"`），需要筛选保留合并报表。

**4. 报告期频率**

数据包含年度（`12-31`）和季度报告，实证研究通常只保留年度数据。

### 探索用的 Stata 代码示例

```stata
* 导入少量样本行，确认数据结构
import delimited "C:/path/FS_Combas.csv", clear rowfirst(5) ///
    encoding("utf8") bindquote(strict)
describe
list stkcd accper typrep a001000000 in 1/3
```

::: callout-note
## 探索阶段的原则

使用 `rowfirst(5)` 限制导入行数，避免加载整个大数据集（资产负债表可达 300+ MB）。优先读取 `.txt` 说明文件了解变量定义，再用 Stata 确认。
:::

## 计划阶段

AI 根据探索结果生成详细的数据处理计划书，包含以下步骤：

1. **预处理**：导入 4 个数据集，保留合并报表（`typrep == "A"`）、保留年度数据（`accper` 以 "12" 结尾）
2. **变量准备**：重命名统一标识符（`Symbol → Stkcd`，`EndDate → Accper`），字符串转数值（`destring`）
3. **去重**：以 `stkcd + year` 为键去重
4. **合并**：以 `stkcd + year` 为键，依次合并 4 个数据集
5. **样本筛选**：剔除金融行业（行业代码 J 开头）、剔除 ST 股票、剔除总资产为负的异常值
6. **变量计算**：计算 Size、Age、Lev、Growth、ROA
7. **缩尾**：对计算的指标在 1%/99% 分位数进行缩尾
8. **描述性统计**：输出均值、标准差、最小值、最大值等

## 执行阶段

确认计划无误后，AI 开始执行。整个过程约 10 分钟。

### 核心代码片段

**导入并筛选年度数据：**

```stata
import delimited "C:/path/FS_Combas.csv", clear ///
    encoding("utf8") bindquote(strict)
* 保留年度数据（12月31日）
gen year = real(substr(accper, 1, 4))
keep if substr(accper, 6, 2) == "12"
* 保留合并报表
keep if typrep == "A"
```

**变量计算：**

```stata
* 公司规模
gen Size = ln(a001000000)

* 公司年龄
gen Age = year - real(substr(listingdate, 1, 4))

* 资产负债率
gen Lev = a002000000 / a001000000

* 资产收益率
gen ROA = b002000000 / a001000000

* 营业收入增长率（需滞后一期）
sort stkcd year
by stkcd: gen Growth = (b001101000 - b001101000[_n-1]) ///
    / abs(b001101000[_n-1]) if _n > 1 & b001101000[_n-1] != 0
```

**剔除金融行业和 ST 股票：**

```stata
* 剔除金融行业（行业代码 J 开头）
drop if substr(industrycode, 1, 1) == "J"

* 剔除 ST 股票
gen is_st = (strpos(shortname, "ST") > 0)
drop if is_st == 1
drop is_st
```

**缩尾处理：**

```stata
foreach var of varlist Size Lev Growth ROA {
    _pctile `var', percentiles(1 99)
    local p1 = r(r1)
    local p99 = r(r2)
    replace `var' = `p1' if `var' < `p1' & !missing(`var')
    replace `var' = `p99' if `var' > `p99' & !missing(`var')
}
```

**描述性统计：**

```stata
tabstat Size Age Lev Growth ROA, stat(n mean sd min p25 p50 p75 max) ///
    col(stat) format(%9.4f)
```

## 输出结果

执行完成后，AI 生成以下文件：

| 输出文件 | 位置 | 说明 |
|----------|------|------|
| 数据处理代码 | `code/` | 完整的、带注释的 `.do` 文件 |
| 清洗后数据 | `data/processed/` | `.dta` 格式的清洗数据集 |
| 工作小结 | `file/` | `.md` 格式的处理报告，包含每步操作和描述性统计结果 |

## 经验总结

1. **CLAUDE.md 至关重要**：提前写明路径规范和目录约定，可以避免大量重复沟通
2. **plan mode 是效率关键**：先探索数据、生成计划，再执行，比直接让 AI 动手效率高得多
3. **表达不确定性是可以的**：在 prompt 中写明"我不确定具体需要哪些操作"，AI 会根据数据结构自行判断并给出建议
