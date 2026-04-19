* 由 Claude Code 使用 stata-data-cleaner skill 生成

* ============================================================
* 01_clean_merge.do
* 清洗合并 A 股上市公司数据，计算常用控制变量
* Size, Age, Lev, Growth, ROA
* ============================================================
clear all
set more off

* ============================================================
* --- 1. 基本信息年度表 ---
* ============================================================
import delimited "C:/Users/13477/Desktop/testskill/data/raw/上市公司基本信息年度表/STK_LISTEDCOINFOANL.csv", clear encoding("utf8") bindquote(strict)

* 重命名以匹配财务表
rename symbol stkcd
rename enddate accper

* 提取年份
gen year = real(substr(accper, 1, 4))

* 保留需要的变量
keep stkcd year shortname industrycode industryname listingdate

* 去重（已在诊断中确认无重复）
duplicates drop stkcd year, force

tempfile info
save `info'

display "基本信息表: " _N " 条"

* ============================================================
* --- 2. 资产负债表 (年报+合并) ---
* ============================================================
import delimited "C:/Users/13477/Desktop/testskill/data/raw/资产负债表/FS_Combas.csv", clear encoding("utf8") bindquote(strict)

* 筛选年报+合并报表
keep if substr(accper, 6, 2) == "12" & typrep == "A"

* 提取年份
gen year = real(substr(accper, 1, 4))

* 保留关键变量
keep stkcd year shortname a001000000 a002000000 a003000000

* 重命名为可读名称
rename a001000000 total_assets
rename a002000000 total_liabilities
rename a003000000 total_equity

duplicates drop stkcd year, force

tempfile balance
save `balance'

display "资产负债表: " _N " 条"

* ============================================================
* --- 3. 利润表 (年报+合并) ---
* ============================================================
import delimited "C:/Users/13477/Desktop/testskill/data/raw/利润表/FS_Comins.csv", clear encoding("utf8") bindquote(strict)

* 筛选年报+合并报表
keep if substr(accper, 6, 2) == "12" & typrep == "A"

gen year = real(substr(accper, 1, 4))

* 保留关键变量
keep stkcd year b001101000 b002000000

rename b001101000 revenue
rename b002000000 net_profit

duplicates drop stkcd year, force

tempfile income
save `income'

display "利润表: " _N " 条"

* ============================================================
* --- 4. 合并数据集 ---
* ============================================================
* 先合并资产负债表和利润表 (1:1)
use `balance', clear
merge 1:1 stkcd year using `income'
display "资产负债表 ∩ 利润表 合并结果:"
tab _merge
keep if _merge == 3
drop _merge
display "合并后: " _N " 条"

* 再合并基本信息表 (1:1)
merge 1:1 stkcd year using `info'
display "合并基本信息表结果:"
tab _merge
keep if _merge == 3
drop _merge
display "合并后: " _N " 条"

* ============================================================
* --- 5. 样本筛选 ---
* ============================================================

* 5.1 剔除金融行业 (J 类)
gen fin_ind = (substr(industrycode, 1, 1) == "J")
tab fin_ind
drop if fin_ind == 1
drop fin_ind
display "剔除金融行业后: " _N " 条"

* 5.2 剔除 ST 股票
gen is_st = (strpos(shortname, "ST") > 0)
tab is_st
drop if is_st == 1
drop is_st
display "剔除 ST 后: " _N " 条"

* 5.3 剔除总资产为负或零的观测
drop if total_assets <= 0 & !missing(total_assets)
display "剔除非正总资产后: " _N " 条"

* ============================================================
* --- 6. 计算控制变量 ---
* ============================================================

* 6.1 Size = ln(总资产)，单位为元，数值很大
gen Size = ln(total_assets)
label variable Size "企业规模 = ln(总资产)"

* 6.2 Age = 当前年份 - 上市年份
gen list_year = real(substr(listingdate, 1, 4))
gen Age = year - list_year
drop if Age < 0
label variable Age "企业年龄 = 年度 - 上市年份"

* 6.3 Lev = 总负债 / 总资产
gen Lev = total_liabilities / total_assets
label variable Lev "资产负债率 = 总负债/总资产"

* 6.4 ROA = 净利润 / 总资产
gen ROA = net_profit / total_assets
label variable ROA "总资产收益率 = 净利润/总资产"

* 6.5 Growth = 营业收入增长率
sort stkcd year
by stkcd: gen revenue_lag = revenue[_n-1]
gen Growth = (revenue - revenue_lag) / abs(revenue_lag) if _n > 1 & revenue_lag != 0 & !missing(revenue_lag)
label variable Growth "营业收入增长率"
drop revenue_lag

* ============================================================
* --- 7. 缺失值检查 ---
* ============================================================
misstable summarize Size Age Lev Growth ROA

* 剔除五个控制变量全部缺失的观测
egen nmiss = rowmiss(Size Age Lev Growth ROA)
tab nmiss
* Growth 首年无滞后值会缺失，这是正常的，不做删除
* 其他变量缺失较多的再考虑删除
drop nmiss

* ============================================================
* --- 8. 缩尾处理 (1st / 99th percentile) ---
* ============================================================
foreach var of varlist Size Age Lev Growth ROA {
    _pctile `var', percentiles(1 99)
    local p1 = r(r1)
    local p99 = r(r2)
    replace `var' = `p1' if `var' < `p1' & !missing(`var')
    replace `var' = `p99' if `var' > `p99' & !missing(`var')
}
display "缩尾完成"

* ============================================================
* --- 9. 变量标签汇总 ---
* ============================================================
label variable stkcd "证券代码"
label variable year "年度"
label variable shortname "证券简称"
label variable industrycode "行业代码"
label variable total_assets "资产总计"
label variable total_liabilities "负债合计"
label variable total_equity "所有者权益合计"
label variable revenue "营业收入"
label variable net_profit "净利润"
label variable listingdate "首次上市日期"

* ============================================================
* --- 10. 描述性统计 ---
* ============================================================
display ""
display "========================================"
display "  描述性统计 (缩尾后)"
display "========================================"
tabstat Size Age Lev Growth ROA, stat(n mean sd min p25 p50 p75 max) col(stat) format(%9.4f)

* ============================================================
* --- 11. 保存清洗后数据 ---
* ============================================================
order stkcd year shortname industrycode Size Age Lev Growth ROA
keep stkcd year shortname industrycode listingdate total_assets total_liabilities total_equity revenue net_profit Size Age Lev Growth ROA
save "C:/Users/13477/Desktop/testskill/data/processed/clean_panel.dta", replace
display "已保存到 data/processed/clean_panel.dta"
display "最终样本量: " _N
