* 由 Claude Code 使用 stata-data-cleaner skill 生成

* ============================================================
* 00_diagnose.do — 数据质量诊断
* ============================================================
clear all
set more off

* ----------------------------------------------------------
* 1. 基本信息年度表
* ----------------------------------------------------------
import delimited "C:/Users/13477/Desktop/testskill/data/raw/上市公司基本信息年度表/STK_LISTEDCOINFOANL.csv", clear encoding("utf8") bindquote(strict)
display "=== 基本信息年度表 ==="
display _N " 条观测"
duplicates report symbol enddate
gen year_info = real(substr(enddate, 1, 4))
tab year_info
gen ind1 = substr(industrycode, 1, 1)
tab ind1
gen ind2 = substr(industrycode, 1, 2)
gen is_fin = (substr(ind2, 1, 1) == "J")
tab is_fin

* ----------------------------------------------------------
* 2. 资产负债表 — 只看年报+合并报表
* ----------------------------------------------------------
import delimited "C:/Users/13477/Desktop/testskill/data/raw/资产负债表/FS_Combas.csv", clear encoding("utf8") bindquote(strict)
display "=== 资产负债表 ==="
display _N " 条观测 (全量)"
keep if substr(accper, 6, 2) == "12" & typrep == "A"
display _N " 条观测 (年报+合并)"
duplicates report stkcd accper
destring a001000000 a002000000 a003000000, replace force
misstable summarize a001000000 a002000000 a003000000
gen year_bas = real(substr(accper, 1, 4))
tab year_bas
gen has_st = (strpos(shortname, "ST") > 0)
tab has_st
count if a001000000 < 0 & !missing(a001000000)
display "负总资产: " r(N)

* ----------------------------------------------------------
* 3. 利润表 — 只看年报+合并报表
* ----------------------------------------------------------
import delimited "C:/Users/13477/Desktop/testskill/data/raw/利润表/FS_Comins.csv", clear encoding("utf8") bindquote(strict)
display "=== 利润表 ==="
display _N " 条观测 (全量)"
keep if substr(accper, 6, 2) == "12" & typrep == "A"
display _N " 条观测 (年报+合并)"
duplicates report stkcd accper
destring b001101000 b002000000, replace force
misstable summarize b001101000 b002000000
gen year_ins = real(substr(accper, 1, 4))
tab year_ins

* ----------------------------------------------------------
* 4. 现金流量表 — 只看年报+合并报表
* ----------------------------------------------------------
import delimited "C:/Users/13477/Desktop/testskill/data/raw/现金流量表(间接法)/FS_Comscfi.csv", clear encoding("utf8") bindquote(strict)
display "=== 现金流量表 ==="
display _N " 条观测 (全量)"
keep if substr(accper, 6, 2) == "12" & typrep == "A"
display _N " 条观测 (年报+合并)"
duplicates report stkcd accper
destring d000101000 d000100000, replace force
misstable summarize d000101000 d000100000
gen year_cfi = real(substr(accper, 1, 4))
tab year_cfi
