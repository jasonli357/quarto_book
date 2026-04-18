# 概述：Claude Code 与 Stata 协同 {#sec-intro}

## 为什么用 Claude Code 配合 Stata

AI Agent（智能体）能够显著提升科研效率，实现多步骤任务的自动化执行。Claude Code 是 Anthropic 推出的一款命令行 AI 编程助手，能够直接在终端中理解项目上下文、执行代码、读写文件。对于经管类研究者而言，将 Claude Code 与 Stata 结合，可以实现：

- 自动化数据处理流程（清洗、合并、计算变量、描述性统计）
- 通过自然语言描述需求，自动生成并执行 Stata 代码
- 将标准化的数据处理流程打包为可复用的"技能包"（Skill），避免重复劳动

## 常见的配置问题

在初次使用 Claude Code 调用 Stata 时，最常遇到的两个问题是：

### 问题一：Claude Code 找不到 Stata

![Claude Code 无法识别 Stata 安装位置](https://fig-lianxh.oss-cn-shenzhen.aliyuncs.com/20260407192905.png)

即使将 Stata 添加到系统环境变量中，Claude Code 有时仍然无法正确定位 Stata 的安装路径。

### 问题二：路径格式不兼容

如果 Claude Code 安装在 WSL（Windows Subsystem for Linux）环境中，而 Stata 安装在 Windows 上，Claude Code 可能使用 WSL 的路径格式调用 Stata：

```bash
# WSL 路径格式 —— Windows 端的 Stata 无法识别
"/d/stata18/StataMP-64.exe" /e do "/mnt/d/work/analysis.do"
```

但 Windows 中的 Stata 只能识别 `D:/work/analysis.do` 这种路径格式，导致路径解析失败。

## 两种解决方案

针对上述问题，本书介绍两种解决方案：

| | 方案一：CLAUDE.md 配置 | 方案二：Stata MCP（推荐） |
|---|---|---|
| **原理** | 在项目配置文件中写明 Stata 路径和运行规则 | 通过 MCP 协议让 AI 与 Stata 自动连接 |
| **优势** | 简单，无需安装额外工具 | 功能强大，支持会话保持和交互执行 |
| **适用场景** | 临时使用、快速上手 | 长期使用、复杂数据处理任务 |
| **前提条件** | 无 | 需要 Stata 授权（`stata.lic`） |

接下来的两章将分别详细介绍这两种方案的配置方法。
