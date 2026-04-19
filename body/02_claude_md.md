# 方案一：在 CLAUDE.md 中配置 Stata {#sec-claude-md}

## 什么是 CLAUDE.md

`CLAUDE.md` 是一个项目级的"说明文件"，放在项目根目录下。Claude Code **每次启动时会自动读取**它，因此可以在其中设定项目的工作规范和约定。

通过在 `CLAUDE.md` 中写明 Stata 的使用规则，可以让 Claude Code 正确地找到 Stata 并以正确的方式执行代码。

## CLAUDE.md 内容

在 `CLAUDE.md` 中，至少应包含以下内容：

### 说明 Stata 安装路径

告诉 Claude Code Stata 可执行文件的确切位置：

```markdown
Stata 安装路径：D:/stata18/StataMP-64.exe
```

### 指定运行 dofile 的终端命令

明确告诉 Claude Code 应该用什么命令来执行 Stata dofile：

```markdown
运行 Stata dofile 的命令：
"D:/stata18/StataMP-64.exe" /e do "script.do"

注意事项：
- 路径使用 Windows 格式（D:/...），不能使用 WSL 格式（/mnt/d/...）
```

::: callout-note
在我的测试中，上述命令有时候会报错，然后 Claude Code 会自行修改，把修改后的命令更新到 CLAUDE.md 即可。
:::

### 规定日志（.log）生成位置

```markdown
日志文件：
- 运行 Stata 前，需先 cd 到项目目录，否则日志会写到默认路径
- 运行完成后，读取同名的 .log 文件查看结果
```

### 错误检测规则

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

## CLAUDE.md 示例

以下是一个适用于命令行模式的 `CLAUDE.md` 示例：

```markdown
## Stata 使用规范

- 路径：`D:\stata18\StataMP-64.exe`
- 批量运行：`"/d/stata18/StataMP-64.exe" /e do "script.do"`
- 运行前先 cd 到 .do 文件所在目录，日志自动生成到该目录，文件名为 `script.log`
- 代码错误检测
  - Stata 退出码不可靠，应检查 .log 文件
  - 若 .log 文件含 `r(` 或缺少 `end of do-file`，说明有代码错误
```