---
name: stata-data-cleaner
description: Clean, merge, and prepare financial datasets for empirical research using Stata. Adaptive workflow — explores data structure, diagnoses quality issues (missing values, duplicates, type mismatches, outliers), consults user on uncertain decisions, generates and executes tailored Stata do files, and produces documentation. Handles CSMAR/Wind/custom CSV data, variable calculation (Size, Age, Lev, ROA, Growth, etc.), winsorization, industry filtering, ST stock removal, missing value analysis, panel data setup, and descriptive statistics. Use this skill whenever the user wants to clean data, preprocess datasets, calculate financial variables, merge datasets, perform descriptive statistics, or prepare data for empirical analysis — even without explicitly mentioning Stata or data cleaning. Also triggers on 缩尾, 清洗, 控制变量, 描述性统计, 合并数据, 数据预处理 in data processing contexts.
---

# Stata Data Cleaner

Clean and prepare financial datasets for empirical research using Stata MCP.

## Core Rules

- **Use Stata MCP** (`mcp__stata-mcp__stata_run_file` or `mcp__stata-mcp__stata_run_selection`) to run Stata. Never call Stata from command line.
- **Windows paths** for Stata MCP: `C:/Users/...`, not WSL `/mnt/c/...`.
- **Never modify raw data**. Save processed data to `data/processed/`, code to `code/`, docs to `file/`.
- **Create directories** (`data/processed/`, `code/`, `file/`) if they don't exist.
- **Check project CLAUDE.md** for additional conventions before starting.

## Workflow Overview

```
Phase 1: Explore  → understand data structure (fast, read-only)
Phase 2: Diagnose → identify quality issues and needed operations
Phase 3: Consult  → ask user about uncertain decisions
Phase 4: Execute  → write and run tailored Stata code
Phase 5: Document → produce .do, .dta, .md outputs
```

Each phase informs the next. Do not skip phases or assume what the data looks like.

---

## Phase 1: Explore Data Structure

Goal: Quickly understand available data **without importing entire datasets** (some files exceed 300 MB).

### 1.1 Scan data directory

List all files and subdirectories where the raw data lives. Identify:
- File formats (.csv, .xlsx, .dta)
- Directory structure (one folder per table? flat?)
- Documentation files (.txt, README, etc.)

### 1.2 Read documentation (fastest path)

**CSMAR data** has `[DES][csv].txt` files alongside each CSV. Read these first — they contain complete variable definitions (name, Chinese label, description, data type). This is the fastest way to understand the schema without touching the data.

For non-CSMAR data, read any README or documentation file.

Extract from documentation:
- Variable names and what they measure
- Key identifiers (stock code variable name, date variable name, report type)
- Data frequency and time coverage
- Variable naming conventions

### 1.3 Sample data via Stata (confirmation only)

For each dataset, import a few rows to **confirm** what the docs say:
```stata
import delimited "C:/path/file.csv", clear rowfirst(2) encoding("utf8") bindquote(strict)
describe
list in 1/3
```

Key things to confirm:
- Actual variable names after import — **`import delimited` lowercases ALL variable names** in Stata
- Whether numeric amounts are stored as strings (need `destring`)
- Date format (YYYY-MM-DD? YYYYMMDD?)
- Identifier format (stock code padded with zeros?)

Do NOT import entire datasets during exploration. Use `rowfirst()` to limit rows.

---

## Phase 2: Diagnose Quality Issues

For each dataset, run targeted diagnostics. Work on filtered samples (e.g., annual only) when possible to save time.

### Required checks:

**2.1 Duplicates**
```stata
duplicates report id_var1 id_var2
```
If duplicates exist, investigate why — multiple report types? restatements? genuine duplicates?

**2.2 Missing values — critical check**
```stata
misstable summarize key_var1 key_var2 key_var3
* Or count manually for specific variables:
count if missing(key_var)
display "Missing rate: " r(N) / _N * 100 "%"
```

Pay special attention to:
- Variables with >10% missing — report this to the user
- Whether missing is systematic (specific years, industries, or company types)
- **Merge risk**: after merging datasets, will missing compound? For example, if Dataset A has 5% missing on variable X and Dataset B has 8% missing on variable Y, the merged dataset might have 13% missing on at least one of them.
- **Calculation risk**: if ROA = NetProfit / TotalAssets and either variable has high missing rates, the resulting ROA will have compounded missingness.

**2.3 Type issues**
```stata
describe key_vars
```
Check if numeric data is stored as strings (common in CSMAR CSVs — empty strings instead of proper missing values). If so, plan `destring, replace force`.

**2.4 Report type and period distribution** (if applicable)
```stata
tab typrep
tab substr(accper, 6, 2)
tab substr(accper, 1, 4)
```

**2.5 Industry distribution** (if applicable)
```stata
tab substr(industrycode, 1, 1)
```

**2.6 Special cases scan**
```stata
* ST / *ST stocks
count if strpos(shortname, "ST") > 0
* Negative total assets
count if total_assets < 0 & !missing(total_assets)
* Zero or negative denominator variables (for ratio calculations)
count if revenue == 0 | revenue < 0
* Extreme values
summarize key_vars, detail
```

**2.7 Merge compatibility** (if multiple datasets)

Check that identifier variables match across datasets:
- Same variable name? (one might use "Symbol", another "Stkcd")
- Same type? (string vs numeric)
- Same format? (e.g., "000001" vs "1")
- Same frequency? (annual vs quarterly)

---

## Phase 3: Consult User

Present your findings and ask for decisions. **Only ask about things that are genuinely uncertain** — if the data has no ST stocks, don't ask whether to remove them.

### Always ask:
1. **What variables to calculate?** — The user's research question determines everything else. Get specific formulas if possible.
2. **Which datasets to merge?** — If multiple datasets exist. Confirm merge keys.

### Ask when relevant (only if the issue exists in the data):
3. **Industry filter?** — Default: remove financial industry. Confirm or adjust.
4. **Remove ST stocks?** — If ST stocks are present. Default: remove.
5. **Remove negative total assets?** — If found. Default: remove.
6. **Winsorization level?** — Default: 1st/99th percentile. Confirm or adjust.
7. **Time period?** — If data spans a very long range and user only needs a subset.
8. **Annual or quarterly?** — If both exist. Most empirical research uses annual.

### Always disclose before merging:
- Obs count in each dataset
- Expected match rate
- How many obs would be lost from unmatched records

Example: "资产负债表有 43,292 条年报，利润表有 43,292 条。合并后预计匹配约 43,000 条。基本信息表有 42,728 条，再合并后预计匹配约 42,500 条，约 800 条可能丢失。"

---

## Phase 4: Generate and Execute Stata Code

Write a complete, well-commented .do file following this structure:

```stata
* ============================================================
* [描述处理目的]
* ============================================================
clear all
set more off

* --- 1. 导入数据 ---
* [import commands]

* --- 2. 变量准备 ---
* [rename, destring, date extraction]

* --- 3. 筛选 ---
* [report type, time period, industry]

* --- 4. 去重 ---
duplicates drop key_vars, force

* --- 5. 合并 ---
* [merge commands, with _merge diagnostics]

* --- 6. 行业/样本筛选 ---
* [remove financial, ST, negative assets, etc.]

* --- 7. 变量计算 ---
* [gen commands for user-requested variables]

* --- 8. 缺失值处理 ---
* [drop missing, or note why not]

* --- 9. 缩尾 ---
* [winsorize specified variables]

* --- 10. 变量标签 ---
* [label variable commands]

* --- 11. 描述性统计 ---
* [tabstat with N, mean, sd, min, p25, p50, p75, max]

* --- 12. 保存 ---
save "output_path.dta", replace
```

### Essential Stata patterns

**Import CSV (handles CSMAR encoding and quotes):**
```stata
import delimited "C:/path/file.csv", clear encoding("utf8") bindquote(strict)
```

**Extract year from date string:**
```stata
gen year = real(substr(datevar, 1, 4))
```

**Filter annual + consolidated (CSMAR convention):**
```stata
keep if substr(accper, 6, 2) == "12" & typrep == "A"
```

**Winsorize without external package:**
```stata
foreach var of varlist var1 var2 var3 {
    _pctile `var', percentiles(1 99)
    local p1 = r(r1)
    local p99 = r(r2)
    replace `var' = `p1' if `var' < `p1' & !missing(`var')
    replace `var' = `p99' if `var' > `p99' & !missing(`var')
}
```

**Lagged variable for growth rates:**
```stata
sort stkcd year
by stkcd: gen growth = (var - var[_n-1]) / abs(var[_n-1]) if _n > 1 & var[_n-1] != 0
```
Note: use `abs()` and add `!= 0` check to handle negative or zero base values safely.

**Merge with diagnostics:**
```stata
merge 1:1 stkcd year using `other'
tab _merge
drop if _merge != 3
drop _merge
```

### Execution and error handling

Execute via Stata MCP. If errors occur:
1. Read the error message — most common are variable name case (Stata lowercases), type mismatch, or missing variable
2. Fix the .do file
3. Re-execute
4. Do NOT blindly retry without fixing

---

## Phase 5: Output and Documentation

### Required outputs

| Output | Location | Description |
|--------|----------|-------------|
| .do file | `code/` | Complete, commented Stata code |
| .dta file | `data/processed/` | Cleaned dataset |
| .md summary | `file/` | Processing report with descriptive stats |

### Summary document template

```markdown
# 数据处理工作小结

## 1. 数据来源
[each source file, obs count, time range, key variables]

## 2. 数据处理操作
[each operation with before → after obs count]
### 2.1 筛选
### 2.2 合并
### 2.3 样本剔除
### 2.4 变量计算
### 2.5 缺失值处理
### 2.6 缩尾

## 3. 最终样本
[obs count, variable list]

## 4. 描述性统计
[table: variable | N | mean | sd | min | p25 | p50 | p75 | max]

## 5. 注意事项
[caveats: why obs were lost, known issues, data limitations]
```

### Descriptive statistics command
```stata
tabstat var1 var2 var3, stat(n mean sd min p25 p50 p75 max) col(stat) format(%9.4f)
```

---

## Common Pitfalls

1. **Variable name case** — `import delimited` lowercases everything. Use lowercase in all Stata code.
2. **String quotes in CSV** — CSMAR wraps values in double quotes. Use `bindquote(strict)`.
3. **Empty strings vs missing** — CSMAR uses empty `""` for missing values. After import, these are empty strings, not Stata missing. Run `destring, replace force` on numeric columns.
4. **Path format** — Stata MCP runs on Windows. Always use `C:/Users/...`, never `/mnt/c/...`.
5. **Large files** — Balance sheets can be 300+ MB. Filter early (keep annual + consolidated first) to reduce memory usage before further processing.
6. **Growth rate denominators** — Check for zero or negative base values before dividing.
7. **Merge key types** — Ensure both sides of a merge use the same type (both string or both numeric).
8. **Duplicate reports** — Some companies file restatements. After filtering, always `duplicates drop` on the merge key.

## When to Read Reference Files

Read `references/operations-guide.md` when you need:
- Detailed guidance on specific cleaning operations (ST stock removal, negative assets, etc.)
- Common financial variable calculation formulas (Size, ROA, Tobin's Q, etc.)
- CSMAR-specific variable code mappings
- Troubleshooting patterns for common Stata errors
