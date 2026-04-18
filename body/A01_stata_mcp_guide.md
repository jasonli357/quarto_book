# 附录 A：Stata MCP 安装与配置指南 {#sec-a1-stata-mcp}

本附录提供 Stata MCP 的详细安装步骤和常见问题解决方法。

## 前提条件

- 有效的 Stata 授权文件（`stata.lic`）
- VS Code 编辑器
- Claude Code CLI

## 安装步骤

### 第一步：安装 VS Code 扩展

1. 打开 VS Code
2. 进入扩展商店（Ctrl+Shift+X）
3. 搜索 "Stata MCP"
4. 点击安装

### 第二步：配置 Stata 路径

1. 打开 VS Code 设置（Ctrl+,）
2. 搜索 "Stata MCP"
3. 在 Stata 安装路径设置中填入你的 Stata 可执行文件所在文件夹（而不是可执行文件本身的路径）
   - Windows 示例：`D:/stata18`
   - 错误示例：`D:/stata18/StataMP-64.exe`
4. 保存设置后，检查 VS Code **右下角状态栏**
5. 如果显示 **"Stata: Connected"**，说明连接成功

### 第三步：在 Claude Code 中注册 MCP 服务器

在终端中运行以下命令：

```bash
claude mcp add --transport sse stata-mcp http://localhost:4000/mcp --scope user
```

> 此命令以及 Stata MCP 服务器在其他代码编辑器（如 Cursor）的配置方式可在 [Stata MCP 的 Github 主页](https://github.com/hanlulong/stata-mcp) 的 "Detailed Configurations" 处找到

- `--scope user` 表示全局注册，所有项目都可以使用
- 如果只想在当前项目中使用，改用 `--scope project`

### 第四步：验证

重启 VS Code 及终端，对 Claude Code 说：“测试一下能否运行 Stata MCP"。

或者尝试手动运行一段简单的 Stata 代码：

```stata
display "Hello from Stata MCP!"
```

如果结果正常返回到对话中，说明配置成功。

## 常见问题

### 问题一："Stata: Connected" 不显示

**可能原因：**

- Stata 路径配置错误
- Stata 授权文件缺失或过期
- VS Code 扩展未正确加载

**解决方法：**

1. 确认 Stata 路径正确（在文件管理器中验证路径是否存在）
2. 检查 `stata.lic` 文件是否在 Stata 安装目录下
3. 重启 VS Code

### 问题二：Claude Code 提示找不到 stata-mcp

**可能原因：**

- MCP 服务器未注册
- Stata MCP 服务未启动

**解决方法：**

1. 没有重启 VS Code 或终端
2. 重新运行注册命令
3. 确认 VS Code 中 Stata MCP 扩展已启用
4. 运行 `claude mcp list` 查看已注册的 MCP 服务器

### 问题三：路径错误 r(601)

**可能原因：**

- Claude Code 使用了 WSL 路径格式（`/mnt/c/...`）

**解决方法：**

在项目 `CLAUDE.md` 中明确写明：

```markdown
Stata MCP 运行在 Windows 端，必须使用 Windows 路径格式
（C:/Users/...），不能用 WSL 的 /mnt/c/... 格式
```

## MCP 管理命令

```bash
# 查看已注册的 MCP 服务器
claude mcp list

# 移除 MCP 服务器
claude mcp remove stata-mcp

# 查看 MCP 服务器详情
claude mcp get stata-mcp
```

或在 claude code 用斜杠命令：`/mcp`