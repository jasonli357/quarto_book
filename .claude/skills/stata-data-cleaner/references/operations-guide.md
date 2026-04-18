# Stata Data Cleaner — Operations Guide

Detailed reference for data cleaning operations. Read this when the main SKILL.md workflow reaches Phase 2 or Phase 4 and you need specific guidance.

## Table of Contents

1. [Import Patterns](#1-import-patterns)
2. [Variable Preparation](#2-variable-preparation)
3. [Filtering Operations](#3-filtering-operations)
4. [Deduplication Strategies](#4-deduplication-strategies)
5. [Merge Strategies](#5-merge-strategies)
6. [Missing Value Handling](#6-missing-value-handling)
7. [Variable Calculation Reference](#7-variable-calculation-reference)
8. [Outlier Treatment](#8-outlier-treatment)
9. [Panel Data Setup](#9-panel-data-setup)
10. [CSMAR Variable Code Reference](#10-csmar-variable-code-reference)

---

## 1. Import Patterns

### CSV (CSMAR standard format)
```stata
import delimited "C:/path/file.csv", clear encoding("utf8") bindquote(strict)
```
- `encoding("utf8")` — CSMAR files are UTF-8 with BOM
- `bindquote(strict)` — values are wrapped in double quotes

### CSV (generic)
```stata
import delimited "C:/path/file.csv", clear
```

### Excel
```stata
import excel "C:/path/file.xlsx", clear firstrow sheet("Sheet1")
```

### Stata .dta
```stata
use "C:/path/file.dta", clear
```

### Import for exploration only (read first N rows)
```stata
import delimited "C:/path/file.csv", clear rowfirst(5) encoding("utf8") bindquote(strict)
```

**Important:** After `import delimited`, ALL variable names are lowercased. A column named `Stkcd` becomes `stkcd`. Plan all code accordingly.

---

## 2. Variable Preparation

### Rename variables for consistency
```stata
rename symbol stkcd          // standardize stock code variable name
rename industrycode industrycode
```

### Convert string to numeric
```stata
* Single variable
destring revenue, replace force

* Multiple variables
destring var1 var2 var3, replace force

* The force option treats non-numeric strings as missing
* Without force, destring will error if it encounters non-numeric strings
```

### Extract year from date string
```stata
* YYYY-MM-DD format (CSMAR standard)
gen year = real(substr(accper, 1, 4))

* YYYYMMDD format
gen year = real(substr(datevar, 1, 4))

* From Stata date value
gen year = year(datevar)
```

### Standardize stock codes (ensure 6-digit format)
```stata
* If stock codes are numeric
gen stkcd_str = string(stkcd, "%06.0f")

* If stock codes are strings but variable length
replace stkcd = "0" + stkcd if length(stkcd) < 6
```

---

## 3. Filtering Operations

### Keep annual reports only
```stata
keep if substr(accper, 6, 2) == "12"
```

### Keep consolidated reports (CSMAR)
```stata
keep if typrep == "A"       // A = consolidated, B = parent company
```

### Remove financial industry
```stata
* By industry code first character (证监会行业分类)
drop if substr(industrycode, 1, 1) == "J"

* Or by specific codes
drop if inlist(substr(industrycode, 1, 2), "J66", "J67", "J68", "J69")
```

### Remove ST / *ST stocks
```stata
gen is_st = (strpos(shortname, "ST") > 0 | strpos(shortname, "*ST") > 0)
drop if is_st == 1
drop is_st
```
ST = Special Treatment. These companies are in financial distress and are typically excluded because their trading behavior and financial ratios are abnormal.

### Remove negative total assets
```stata
drop if totalassets < 0 & !missing(totalassets)
```
Negative total assets indicate severe financial distress or data errors.

### Time period filter
```stata
keep if year >= 2010 & year <= 2023
```

### Remove IPO year observations
```stata
* Some researchers exclude IPO year because first-year data is often incomplete
gen ipo_year = real(substr(listingdate, 1, 4))
drop if year == ipo_year
```

---

## 4. Deduplication Strategies

### Simple deduplication
```stata
duplicates drop stkcd year, force
```

### Handle restatements (keep latest version)
If a company files a restated report, there may be multiple records for the same stkcd-year. Decide:
- **Keep latest filing** (common approach):
  ```stata
  * Sort so latest filing is last
  sort stkcd year declaredate
  * Keep the last (latest) record
  duplicates drop stkcd year, force
  ```
- **Keep first filing** (original):
  ```stata
  sort stkcd year accper
  duplicates drop stkcd year, force
  ```

### Before deduplication, always check
```stata
duplicates report stkcd year
duplicates tag stkcd year, gen(dup)
tab dup
list stkcd year if dup > 0
```

---

## 5. Merge Strategies

### 1:1 merge (same units, different variables)
```stata
* E.g., merge balance sheet + income statement on stkcd + year
merge 1:1 stkcd year using `other_dataset'
```
Use when: each observation in both datasets is uniquely identified by the merge keys.

### m:1 merge (many-to-one)
```stata
* E.g., merge company-year data with company-level basic info
merge m:1 stkcd year using `basic_info'
```
Use when: the "using" dataset has one record per key combo but the "master" may have multiple.

### Merge diagnostics — always do this
```stata
merge 1:1 stkcd year using `other'
tab _merge
* _merge == 1: only in master
* _merge == 2: only in using
* _merge == 3: matched
drop if _merge != 3
drop _merge
```

### Cross-dataset identifier mismatches
Common issue: one dataset uses `Symbol` while another uses `Stkcd`. Or one stores stock codes as string, another as numeric.
```stata
* Before merging, ensure keys match in name and type
rename symbol stkcd          // name match
destring stkcd, replace      // type match (or tostring)
```

---

## 6. Missing Value Handling

### Analyze missing patterns
```stata
* Quick overview
misstable summarize

* Missing count and rate for specific variables
count if missing(var)
display "Missing rate: " %5.2f r(N)/_N * 100 "%"

* Pattern by year
tab year if missing(var)

* Pattern by industry
tab substr(industrycode, 1, 1) if missing(var)
```

### Strategies
1. **Listwise deletion** (most common in empirical finance): drop obs with any missing on key variables.
   ```stata
   drop if missing(var1) | missing(var2) | missing(var3)
   ```
2. **Keep but flag**: create a missing indicator, useful for robustness checks.
   ```stata
   gen missing_var1 = missing(var1)
   ```
3. **Do nothing**: for some analyses, Stata handles missing automatically (regression drops obs with missing).

### When to alert the user
- Any variable with >10% missing → report the rate
- Missing that compounds across merge steps → calculate expected final sample size
- Systematic missing (e.g., all missing in early years) → this may indicate the variable wasn't collected then

---

## 7. Variable Calculation Reference

Common financial variables in empirical research:

### Firm-level characteristics
| Variable | Formula | Source Variables |
|----------|---------|-----------------|
| Size | ln(总资产) | A001000000 |
| Age | 当年年份 - 上市年份 | LISTINGDATE |
| Lev | 负债合计 / 资产总计 | A002000000 / A001000000 |
| ROA | 净利润 / 资产总计 | B002000000 / A001000000 |
| ROE | 净利润 / 所有者权益合计 | B002000000 / A003000000 |
| Growth | (本期营收 - 上期营收) / \|上期营收\| | B001101000 (lagged) |
| Cash | 货币资金 / 资产总计 | A001101000 / A001000000 |
| Tangibility | 固定资产净额 / 资产总计 | A001212000 / A001000000 |
| CurrentRatio | 流动资产合计 / 流动负债合计 | A001100000 / A002100000 |

### Growth rate calculation (safe version)
```stata
sort stkcd year
by stkcd: gen growth = (revenue - revenue[_n-1]) / abs(revenue[_n-1]) if _n > 1 & revenue[_n-1] != 0
```
Using `abs()` in denominator handles cases where prior-year revenue is negative.

### Log transformation
```stata
gen ln_assets = ln(totalassets)
```
Only apply to strictly positive values. Negative or zero values will produce missing.

### Ratio variables
```stata
gen lev = total_liab / total_assets
```
Always check for zero denominators: `count if total_assets == 0`.

---

## 8. Outlier Treatment

### Winsorize (manual, no external package needed)
```stata
foreach var of varlist var1 var2 var3 {
    _pctile `var', percentiles(1 99)
    local p1 = r(r1)
    local p99 = r(r2)
    replace `var' = `p1' if `var' < `p1' & !missing(`var')
    replace `var' = `p99' if `var' > `p99' & !missing(`var')
}
```

### Different winsorization levels
- **1%/99%**: standard in most empirical finance papers
- **5%/95%**: more aggressive, useful when data is very noisy
- **Asymmetric**: e.g., 1% lower, 99% upper (standard is symmetric)

### Before winsorizing, always check
```stata
summarize var, detail
```
This shows percentiles and extreme values. Make sure winsorization targets are reasonable.

### What to winsorize
- **Always winsorize**: ratio variables (Lev, ROA, Growth, etc.) — these are prone to extreme outliers
- **Usually winsorize**: calculated variables from financial data
- **Usually NOT winsorize**: log-transformed variables (log already compresses extremes), count variables, categorical variables

---

## 9. Panel Data Setup

### Declare panel structure
```stata
xtset stkcd year
```
This enables panel data commands (xtreg, etc.) and verifies the panel structure.

### Check panel balance
```stata
xtdescribe
```
Reports how many panels are balanced vs unbalanced.

### Generate lag/lead variables (panel-aware)
```stata
sort stkcd year
by stkcd: gen lag_var = var[_n-1]
by stkcd: gen lead_var = var[_n+1]
```
Or with xt commands:
```stata
xtset stkcd year
gen lag_var = L.var
gen lead_var = F.var
```

---

## 10. CSMAR Variable Code Reference

### Balance Sheet (FS_Combas)
| Code | Description |
|------|-------------|
| A001000000 | 资产总计 |
| A002000000 | 负债合计 |
| A003000000 | 所有者权益合计 |
| A001101000 | 货币资金 |
| A001111000 | 应收账款净额 |
| A001123000 | 存货净额 |
| A001100000 | 流动资产合计 |
| A001200000 | 非流动资产合计 |
| A001212000 | 固定资产净额 |
| A002100000 | 流动负债合计 |
| A002200000 | 非流动负债合计 |
| A002101000 | 短期借款 |
| A002201000 | 长期借款 |
| A003101000 | 实收资本(或股本) |

### Income Statement (FS_Comins)
| Code | Description |
|------|-------------|
| B001100000 | 营业总收入 |
| B001101000 | 营业收入 |
| B001201000 | 营业成本 |
| B002000000 | 净利润 |
| B002000101 | 归属于母公司所有者的净利润 |
| B001000000 | 利润总额 |
| B001300000 | 营业利润 |

### Cash Flow Statement (FS_Comscfi)
| Code | Description |
|------|-------------|
| C001000000 | 经营活动产生的现金流量净额 |
| C002000000 | 投资活动产生的现金流量净额 |
| C003000000 | 筹资活动产生的现金流量净额 |

### Basic Info (STK_LISTEDCOINFOANL)
| Code | Description |
|------|-------------|
| Symbol | 股票代码 (note: not "Stkcd") |
| IndustryCode | 行业代码 (证监会分类, J开头 = 金融业) |
| LISTINGDATE | 首次上市日期 |

### Report type codes
| Value | Meaning |
|-------|---------|
| A | 合并报表 (Consolidated) |
| B | 母公司报表 (Parent company) |

### Accounting period codes (Accper)
- `YYYY-01-01` — 期初数 (beginning of year balance)
- `YYYY-03-31` — Q1
- `YYYY-06-30` — H1 (semi-annual)
- `YYYY-09-30` — Q3
- `YYYY-12-31` — Annual

For annual data analysis, keep only `YYYY-12-31` records.

### Industry code prefix (证监会2012版)
| Prefix | Industry |
|--------|----------|
| A | 农林牧渔 |
| B | 采矿业 |
| C | 制造业 |
| D | 电力热力燃气水 |
| E | 建筑业 |
| F | 批发零售 |
| G | 交通运输仓储邮政 |
| H | 住宿餐饮 |
| I | 信息传输软件IT |
| J | 金融业 (**usually removed**) |
| K | 房地产 |
| L | 租赁商务服务 |
| M | 科学研究技术服务 |
| N | 水利环境公共设施 |
| O | 居民服务修理 |
| P | 教育 |
| Q | 卫生社会工作 |
| R | 文化体育娱乐 |
| S | 综合 |
