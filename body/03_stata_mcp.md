# 方案二：安装 Stata MCP（推荐） {#sec-stata-mcp}

## 什么是 Stata MCP

MCP（Model Context Protocol）是一种让 AI 模型与外部工具交互的协议。Stata MCP 是基于此协议开发的工具，它将 Stata 变成了一个**可交互的服务**，而不是每次冷启动一个独立进程。

## 安装步骤

安装 Stata MCP 需要以下步骤：

![Stata MCP 架构](https://fig-lianxh.oss-cn-shenzhen.aliyuncs.com/20260407205148.png)

### 1. 在 VS Code 安装 Stata MCP 插件

在 VS Code 扩展商店中搜索并安装 Stata MCP 插件。

### 2. 设置 Stata 安装路径

在插件设置中填入 Stata 的安装路径。设置完成后，VS Code 右下角应显示 **"Stata: Connected"**，表示连接成功。

### 3. 在 Claude Code 中添加 Stata MCP 服务器

在终端中运行以下命令，将 Stata MCP 注册到 Claude Code：

```bash
claude mcp add --transport sse stata-mcp http://localhost:4000/mcp --scope user
```

::: callout-important
## 前提条件

使用 Stata MCP 需要有效的 Stata 授权文件（`stata.lic`）。如果没有授权，请使用方案一（CLAUDE.md 配置）。
:::

## Stata MCP 的功能

Stata MCP 提供两个核心工具：

- **`stata_run_file`**：运行完整的 `.do` 文件
- **`stata_run_selection`**：直接运行代码片段，无需创建文件
- **多会话模式**：通过不同的 `session_id` 可以并行运行多个 Stata 实例

## 命令行 vs Stata MCP 对比

既然 Claude Code 可以用命令行方式执行 Stata（`"/d/stata18/StataMP-64.exe" /e do "script.do"`），那 Stata MCP 还有什么意义？

### 命令行方式的流程

执行一次分析需要 **3 步**：

1. `Write` — 创建 `.do` 文件
2. `Bash` — 执行 `StataMP-64.exe /e do script.do`
3. `Read` — 读取 `.log` 文件查看结果

而且每次运行都是**启动一个新的 Stata 进程**，上次加载数据的状态不会保留。

### Stata MCP 的流程

**1 步搞定**：

1. `stata_run_selection` — 直接传入代码，结果立即返回到对话中

### 详细对比

| 对比项 | 命令行 `/e` | Stata MCP |
|--------|------------|-----------|
| 工具调用次数 | 3 次（Write → Bash → Read） | 1 次 |
| 需要创建文件 | 是 | 否（用 `stata_run_selection` 直接运行代码片段） |
| 结果获取 | 需手动读 .log | 直接返回到对话 |
| 会话保持 | 每次全新启动 | 可复用同一会话 |
| 数据加载 | 每次重新加载 | 加载一次，后续复用 |
| 并行执行 | 需手动管理 | 用不同 `session_id` 即可 |

### 会话保持的关键优势

**最大的实际意义是「会话保持」**。在 Stata MCP 中，可以像平时和 Stata 交互一样，在同一个窗口内多次执行命令：

```stata
* 第 1 次运行
use "data.dta"          // 数据加载到内存

* 第 2 次运行
summarize income        // 直接对已加载的数据做分析

* 第 3 次运行
reg y x1 x2            // 继续在同一个数据上回归
```

而命令行方式每次都得重新加载数据，对于大数据集来说非常浪费时间。

## 小结

**Stata MCP 就是把 Stata 变成了一个可交互的服务**，而不是每次冷启动一个独立进程。对于需要反复执行 Stata 代码的数据处理任务，Stata MCP 能显著提升效率。
