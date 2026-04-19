# Skills 简介 {#sec-skills}

## 什么是 Skills

**Skills**（技能）是一组打包在指定文件夹中的 **prompt + 程序 + 参考文件**。它们可以让 Claude Code 在特定任务中表现得更加专业和稳定。

Skills 的核心优势：

- 把标准化流程打包，**可复用**
- AI 只读取 `SKILL.md` 的元数据，判断要不要调用这个 Skill；要调用时再读取 Skill 里面的其他文件，**节省 token 消耗和上下文空间**

## Skills 的目录结构

一个标准的 Skill 文件夹结构如下：

```
.claude/
└── skills/
    └── skillname/
        ├── SKILL.md        # 核心文件，必须有（含元数据和具体 prompt 描述）
        ├── scripts/        # 可选 — 程序脚本（Python 等）
        ├── assets/         # 可选 — 模板和资源文件
        ├── references/     # 可选 — 参考文档（说明手册、规范文档）
        └── 其他文件夹，如 agents/    # 可选 — 因 skill 需求而已
```

其中 **`SKILL.md`** 是核心定义文件，包含：

- **元数据**：名称、简介、触发条件（description 字段中的关键词）
- **Prompt 内容**：指导 AI 如何执行这个 Skill 的详细指令

## 示例：skill-creator

以 Anthropic 官方的 `skill-creator` 为例，其核心结构如下：

```
.claude/skills/skill-creator/
├── SKILL.md              # 核心定义文件
├── agents/               # 评估、对比和打分的子代理
│   ├── analyzer.md
│   ├── comparator.md
│   └── grader.md
├── assets/               # 前端模板等资源
│   ├── eval_review.html
│   └── eval-viewer/
├── references/           # JSON/YAML Schema 等规范文档
│   └── schemas.md
└── scripts/              # 自动化脚本
    ├── run_eval.py       # 执行技能测试与评估
    ├── generate_report.py # 生成测试报告
    ├── improve_description.py # 优化触发描述词
    └── ...
```

### skill-creator 的工作原理

**功能**：这是一个"用来创建技能的技能"。它可以协助用户从零开始搭建新技能、优化已有技能的触发词描述、执行自动化基准测试（Eval），并分析性能表现。

**工作原理**：

1. **识别指令，创建 Skill**：通过识别用户诸如"创建新技能"的意图，触发 `SKILL.md` 中的系统提示词
2. **执行脚本，测试和改进 Skill**：调用 `scripts/` 中的 Python 脚本来测试 Skill，然后根据 `assets/` 提供的模板呈现结果

### 核心文件的作用

- **`SKILL.md`**：核心定义文件。包含元数据以及指导 AI 创建和优化其他技能的 Prompt 指示
- **`scripts/`**：存放核心功能的 Python 脚本
- **`assets/`**：存放辅助执行的资源文件
- **`references/`**：提供背景及规范知识库
- **`agents/`**：对技能进行评估、对比和打分的子代理

## 发现与安装 Skills

详见 [常用斜杠命令](05_slash_commands.md)【发现与安装 Skills】部分

> skill-creator 也包含在 Anthropic 官方技能包 https://github.com/anthropics/skills.git 里面


