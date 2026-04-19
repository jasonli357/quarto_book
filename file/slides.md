---
### ------------------- 幻灯片还是普通网页
marp: true
#marp: false

### ------------------- 幻灯片尺寸，宽版：4:3
size: 16:9
#size: 4:3

### ------------------- 是否显示页码
paginate: true  
#paginate: false

### ------------------- 页眉 (备选的用 '#' 注释掉)
#header: lianxh.cn
#header: '[连享会](https://www.lianxh.cn)'
#header: '[lianxh.cn](https://www.lianxh.cn/news/46917f1076104.html)'

### ------------------- 页脚 (备选的用 '#' 注释掉)
#footer: 'lianx.cn Marp 模板'
#footer: '连享会&nbsp;|&nbsp;[lianxh.cn](https://www.lianxh.cn)&nbsp;|&nbsp;[Bilibili](https://space.bilibili.com/546535876)'
#footer: '![20230202003318](https://fig-lianxh.oss-cn-shenzhen.aliyuncs.com/20230202003318.png)'
math: mathjax
---

<!-- 
Notes: 
1. 选中一段文本，按快捷键 'Ctrl+/' 可以将其注释掉；再次操作可以解除 
2. header, footer 后面的文本需要用单引号引起来，否则会有语法错误
3. '#size: 16:9' 不能写为 'size:16:9'，即 'size:' 后要有一个空格
-->

<!-- Global style: 设置标题字号、颜色 -->
<!-- Global style: 正文字号、颜色 -->
<style>
/*一级标题局中*/
section.lead {
  text-align: center; /*其他参数：left, right*/
  /*使用方法：
  <!-- _class: lead -->
  */
}
section {
  font-size: 24px; 
}
h1 {
  color: blackyellow;
}
h2 {
  color: green;
}
h3 {
  color: darkblue;
}
h4 {
  color: brown;
  /*font-size: 28px; */
}
/* 右下角添加页码 */
section::after {
  /*font-weight: bold; */
  /*text-shadow: 1px 1px 0 #fff; */
/*  content: 'Page ' attr(data-marpit-pagination) ' / ' attr(data-marpit-pagination-total); */
  content: attr(data-marpit-pagination) '/' attr(data-marpit-pagination-total); 
}
header,
footer {
  position: absolute;
  left: 50px;
  right: 50px;
  height: 25px;
}
</style>

<!-- _class: lead -->

# Claude Code 协同 Stata：环境配置与应用实践

<br>

报告人：黎佳迅

中山大学岭南学院硕士研究生

2026.4.23

--- -- -

## 内容大纲

### 一、Stata 环境配置

### 二、Claude Code 基本交互技巧

### 三、用 Claude Code 清洗 CSMAR 企业财务数据

### 四、skill 简介和创建数据处理 skill

--- -- -

本次分享的内容手册链接：

![](https://fig-lianxh.oss-cn-shenzhen.aliyuncs.com/https___jasonli357.github.io_Claudecode_Stata_.png)

> 本次分享涉及的全部资料：https://github.com/jasonli357/Claudecode_Stata
> 内容手册：https://jasonli357.github.io/Claudecode_Stata/
> 关于 Claude Code 的安装，可参考：https://jasonli357.github.io/Claudecode_Stata/body/11_references.html

--- -- -

## 一、Stata 环境配置

### 用 Claude Code 运行 Stata 会遇到什么问题？

**1. Claude Code 不知道 Stata 安装在哪里**

![w:550](https://fig-lianxh.oss-cn-shenzhen.aliyuncs.com/20260407192905.png)

即使把 stata 放进环境路径里，有时还是找不到。

--- -- -

**2. Claude Code 在终端调用 Stata 执行 dofile 时，可能用了错误的路径格式** 

如果 Claude Code 安装在 WSL，而 Stata 安装在 Windows 上，Claude Code 可能使用如下终端命令：

```bash
stata -b do /mnt/d/work/analysis.do  # /mnt/d/... 是 WSL 的路径格式
```

但 Windows 里的 Stata 只能识别 `D:/work/analysis.do` 这种路径格式

--- -- -

### 方案 1：在 `CLAUDE.md` 中设定 Stata 使用规则

CLAUDE.md 就是一个**项目级的"说明文件"**，Claude Code **每次启动时会自动读取**它。可以在 CLAUDE.md 写以下内容：

1. 说明 Stata 安装路径
2. 指定运行 dofile 的终端命令
3. 规定日志（.log）生成位置
   - 运行前需先 cd 到项目目录，否则日志会写到默认路径
4. 根据日志检测代码错误

--- -- -

### 方案 2：安装 Stata MCP（需要有 STATA.LIC）

![w:400](https://fig-lianxh.oss-cn-shenzhen.aliyuncs.com/20260407205148.png)

1. 在 VS Code 安装 Stata MCP 插件
2. 设置 Stata 安装路径（这一步完成后，VS Code 右下角会显示 "Stata: Connected"）
3. 在 Claude Code 添加 Stata MCP 服务器

```
claude mcp add --transport sse stata-mcp http://localhost:4000/mcp --scope user
```

--- -- -

### Stata MCP 的功能

- 运行 .do 文件（`stata_run_file`）
- 运行代码片段（`stata_run_selection`）
- 支持多会话模式（可并行运行多个 Stata 实例）

> 既然 claude code 可以用【 "/d/stata18/StataMP-64.exe" /e do "script.do"】这种命令行方式运行 stata，那 stata-mcp 还有什么意义？

- 命令行方式相当于每次运行都打开一个新的 stata 窗口，运行完 dofile 后自动关闭。
- Stata MCP 能让 AI 像我们平时和 Stata 交互一样，在同一个窗口内多次执行 stata 命令。

| 对比项 | 命令行 `/e` | stata-mcp |
|-------|-----------|-----------|
| 需要创建 `.do` 文件 | 是 | 否（用 `stata_run_selection` 工具直接运行代码片段） |
| 结果获取 | 需手动读 log | 直接返回 |
| 会话保持 | 每次全新启动 | 可复用同一会话 |
| 数据加载 | 每次重新加载 | 加载一次，后续复用 |


--- -- -

### 二、Claude Code 基本交互技巧

#### 执行权限控制
- claude --dangerously-skip-permissions
- claude --permission-mode auto
  - 使用一个后台 AI 替你判断命令是否有风险
  - claude 官方模型 sonnet/opus 可用，GLM 等第三方模型不可用
- 在 `.claude\settings.json` 或 `.claude\settings.local.json` 里配置白名单，白名单里的命令不需要询问用户许可
  - 每次 claude code 询问是否允许某个操作时，如果选 "Yes, and don't ask again for ..."，ai 就会在 `.claude\settings.local.json` 的白名单里自动添加这个命令
  - 如果不确认添加某个命令是否有风险，可以在 AI 征求某个命令的许可之后，马上用 `/btw` 问问 AI。

--- -- -

#### 发现、安装并管理官方及第三方技能包
1. 通过 `/plugin` 下载和管理
2. 直接用自然语言把网址发给 ai，让它下载
3. 手动下载网页上的 skill，移动到系统级或者项目级的 `.claude/skills` 文件夹
   - 系统级：`~/.claude`（Windows：`C:\Users\13477\.claude`）
   - 项目级：`/mnt/c/Users/13477/Desktop/claude_stata/.claude`

例子：  
Anthropic 官方的 Skills 仓库：https://github.com/anthropics/skills.git  

--- -- -

#### 常用斜杠命令（Slash Commands）
- /resume：查看和恢复历史会话
- /btw：运行过程中对话，不打断当前进程；回答完自动消失，不污染上下文
- /branch：分支
- /rewind：回退
- /export：导出会话记录
- /insights：生成一份 HTML 报告，分析用户过去一个月使用 Claude Code 的习惯，给出使用建议

--- -- -

### 三、用 Claude Code 清洗 CSMAR 企业财务数据

任务：从企业基本信息和财务报表数据中，计算 5 个企业特征：公司规模（Size）、年龄（Age）、资产负债率（Lev）、营业收入增长率（Growth）、资产收益率（ROA）

#### Step 1：个人工作习惯和希望 AI 工作的方式，在 CLAUDE.md 里写明

- 通过 Stata-mcp 调用 Stata，不要用命令行。
- 原始数据在 `data/raw/` 目录下，不要修改或覆盖；清洗过程中以及清洗后的数据存入 `data/processed/`
- 代码放在 `code/`
- 说明文档放在 `file/`
- Stata MCP 运行在 Windows 端，必须使用 Windows 路径格式（`C:/Users/...`），不能用 WSL 的 `/mnt/c/...` 格式，否则报 `r(601) file not found`

--- -- -

> 完善 CLAUDE.md：可以在 AI 执行完任务后，问它刚刚有没有遇到问题。然后让它总结经验，写进 `CLAUDE.md` 里面。

![w:800](https://fig-lianxh.oss-cn-shenzhen.aliyuncs.com/20260417150701.png)

--- -- -

#### Step 2：打开 plan mode，具体说明任务需求（用什么工具、有哪些步骤、最后要输出什么），自己对需求不确定的地方也可以写明，让 AI 完善

【prompt】
```
【data/】里面是实证金融研究用的 A 股上市公司数据，需要清洗合并后计算常用控制变量
（Size、Age、Lev、Growth、ROA），对这些指标进行描述性统计。用 stata 完成。

注意事项：删除金融行业（行业代码J*）、计算出的指标要缩尾

- 我不确定具体要执行哪些数据清洗操作，需要你结合数据结构和数据处理的惯例判断

最后输出三个文件：处理数据的.do文档；处理后数据集.dta文件；数据处理工作小结.md文档
（包含数据处理操作和最后的描述性统计结果）
```

> 一些常规的数据处理操作（例如缩尾），即使不写，AI 有时候也会自己判断出需要执行，但结果不稳定。

#### Step 3：确认计划没问题后，开始执行

> 用时约 10 min

--- -- -

### 四、skill 简介和创建数据处理 skill

#### 1. 什么是 Skills？
**Skills**（技能）是一组打包在指定文件夹中的【prompt + 程序 + 参考文件】

#### 2. Skills 的结构

```
.claude/
└── skills/
    └── skillname/
        ├── SKILL.md        # 核心文件，必须有（含元数据和具体 prompt 描述）
        ├── scripts/        # 可选 - 程序脚本
        ├── assets/         # 可选 - 模板和资源
        └── references/     # 可选 - 参考文档（说明手册、规范文档）
```

--- -- -

#### 3. 例子：skill-creator

以 `.claude/skills/skill-creator` 为例，其核心结构如下：

#### skill-creator 的工作原理与功能

**功能**：这是一个“用来创建技能的技能”。它可以协助用户从零开始搭建新技能、优化已有技能的触发词描述、执行自动化基准测试（Eval），并分析性能表现。

**工作原理**：
1. **识别指令，创建 skill**：通过识别用户诸如“创建新技能”的意图，触发 `SKILL.md` 中的系统提示词，创建 skill。
2. **执行脚本，测试和改进 skill**：调用 `scripts/` 中的 Python 脚本来测试 skill，然后根据 `assets/` 提供的模板呈现结果。

--- -- -

#### 核心文件与文件夹的作用

- **`SKILL.md`**: 核心定义文件。包含元数据（名称、技能简介、触发条件）以及指导大语言模型创建和优化其他技能的 Prompt 指示。
- **`scripts/`**: 存放核心功能的 Python 脚本，用于执行自动化操作，例如：
  - `run_eval.py` / `run_loop.py`: 用于执行技能测试与评估。
  - `generate_report.py` / `aggregate_benchmark.py`: 用于收集测试结果并生成技能基准数据报告。
  - `improve_description.py`: 帮助优化技能的触发描述词。
  - `package_skill.py`: 打包和构建技能包。
  - `quick_validate.py`: 快速验证技能结构的正确性。
- **`assets/`**: 存放辅助执行的资源文件。如 `eval_review.html` 提供了展示技能测试评估结果的前端页面的模板。
- **`references/`**: 提供背景及规范知识库，如 `schemas.md` 中保存了各种配置文件和所需 JSON/YAML 结构的 Schema 信息。
- **`agents/`**：对技能进行评估、对比和打分的三个 agent，在相应环节自动调用。

--- -- -

#### 4. Skills 的优点

- 把标准化流程打包，可复用
- AI 只读取 SKILL.md 的元数据，判断要不要调用这个 skill，要调用时再读取 skill 里面的其他文件，节省 token 消耗和上下文空间

**为什么要创建数据处理 skill？**

让 AI 处理数据时，不用每次都说明剔除ST股、剔除金融业、指标要缩尾等等要求。

- 向 AI 说明的数据处理的具体要求（例如剔除哪些样本）
- 给 AI 制定工作规范（例如变量标签怎么写、最后输出什么文件）

--- -- -

#### 5. 创建数据处理 skill 

在 plan mode 下输入如下 prompt：

```
现在 @data/raw/ 里面的数据清洗完了。请你把清洗数据的流程打包成一个skill，放在当前项目文件夹。
参考 @file/plan.md, @file/data_processing_summary.md 的清洗流程和 @code/data_cleaning.do 的清洗代码，让skill实现以下功能：

1. 这个 skill 要自己探索数据结构（尽可能快速，不要扫描整个大型数据集，可以通过stata代码或者阅读数据里面的.txt说明文件来探索）     
2. 然后要全面检查各种具体的数据预处理操作（包括但不限于：保留合并报表、保留年度数据、统一变量名、字符型转为数值型变量、
   剔除金融行业样本、剔除 ST 样本、剔除总资产为负等异常值、剔除上市不到一年样本、去重、缩尾等等）是否需要进行；
3. 尤其关注缺失值的情况。例如：合并数据集后，会不会某一个数据大量确实导致合并数据集大量缺失；计算某个指标时，
   会不会某个变量存在大量缺失值，导致这个指标存在大量缺失；
4. 如果不确定某个操作是否需要进行、怎么进行，要向我提问。
5. 根据我的需求，判断是只要处理单个数据集，还是要合并多个数据集
6. 根据我的需求，保留和计算我需要的变量
7. 清洗完成后，对重要的变量进行描述性统计

最终输出包括：数据处理的 .do 文档；处理后的 .dta 文件；数据处理工作小结 .md 文档（包含进行了哪些操作，以及最后的描述性统计）

用 stata 完成上述任务。用 stata mcp 调用 stata，不要用命令行调用。

因为每次用这个skill处理的数据结构可能不一样，这个skill考虑到的情况要尽可能全面，确保泛用性。

如果有什么我没提到但在其他数据清洗任务中常见的操作，请你补充。

另外，不知道上述功能全部放进一个skill比较好，还是分别放进几个不同的skill比较好。请你给出建议。
```

> 创建 skill 用时约 7 min；用 skill 清洗数据用时约 7 min

--- -- -

本次分享的内容手册链接：

![](https://fig-lianxh.oss-cn-shenzhen.aliyuncs.com/https___jasonli357.github.io_Claudecode_Stata_.png)

> 本次分享涉及的全部资料：https://github.com/jasonli357/Claudecode_Stata
> 内容手册：https://jasonli357.github.io/Claudecode_Stata/
> 关于 Claude Code 的安装，可参考：https://jasonli357.github.io/Claudecode_Stata/body/11_references.html