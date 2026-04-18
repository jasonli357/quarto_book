# 方案一：在 CLAUDE.md 中配置 Stata {#sec-claude-md}

## 什么是 CLAUDE.md

`CLAUDE.md` 是一个项目级的"说明文件"，放在项目根目录下。Claude Code **每次启动时会自动读取**它，因此可以在其中设定项目的工作规范和约定。

通过在 `CLAUDE.md` 中写明 Stata 的使用规则，可以让 Claude Code 正确地找到 Stata 并以正确的方式执行代码。

## 配置内容

在 `CLAUDE.md` 中，至少应包含以下内容：

### 1. 说明 Stata 安装路径

告诉 Claude Code Stata 可执行文件的确切位置：

```markdown
Stata 安装路径：D:/stata18/StataMP-64.exe
```

### 2. 指定运行 dofile 的终端命令

明确告诉 Claude Code 应该用什么命令来执行 Stata dofile：

```markdown
运行 Stata dofile 的命令：
"D:/stata18/StataMP-64.exe" /e do "script.do"

注意事项：
- 路径使用 Windows 格式（D:/...），不能使用 WSL 格式（/mnt/d/...）
- /e 参数表示 batch 模式，运行完自动关闭
```

### 3. 规定日志（.log）生成位置

```markdown
日志文件：
- 运行 Stata 前，需先 cd 到项目目录，否则日志会写到默认路径
- 运行完成后，读取同名的 .log 文件查看结果
```

### 4. 错误检测规则

```markdown
错误检测：
- 检查 .log 文件中是否包含 "r(" 开头的错误代码
- 如果发现错误，分析错误原因并修改 .do 文件后重新运行
```

## 完善 CLAUDE.md 的技巧

`CLAUDE.md` 不是一次写完就固定的文件。一个实用的做法是：

> 在 AI 执行完任务后，问它刚刚有没有遇到问题。然后让它总结经验，写进 `CLAUDE.md` 里面。

![完善 CLAUDE.md 的过程](https://fig-lianxh.oss-cn-shenzhen.aliyuncs.com/20260417150701.png)

这样随着使用，`CLAUDE.md` 会不断完善，AI 的工作效率和准确度也会逐步提升。

## 完整示例

以下是一个适用于命令行模式的 `CLAUDE.md` 示例：

```markdown
## Stata 数据处理规范

- Stata 安装路径：D:/stata18/StataMP-64.exe
- 运行 dofile 命令："D:/stata18/StataMP-64.exe" /e do "script.do"
- 运行前需先 cd 到项目目录
- 路径格式必须使用 Windows 格式（D:/...），不能用 WSL 的 /mnt/d/... 格式

- 原始数据在 data/raw/ 目录下，不要修改或覆盖
- 清洗过程中以及清洗后的数据存入 data/processed/
- 代码放在 code/
- 说明文档放在 file/

- 运行完成后，读取 .log 文件检查是否有 r( 开头的错误代码
```

::: callout-note
方案一虽然简单，但每次执行 Stata 代码都需要经历"写 .do 文件 → 执行命令 → 读 .log 文件"三个步骤，且每次运行都会启动一个新的 Stata 进程。如果希望更高效的交互体验，推荐使用方案二（Stata MCP）。
:::
