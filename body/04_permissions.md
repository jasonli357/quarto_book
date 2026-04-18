# 执行权限控制 {#sec-permissions}

Claude Code 在执行某些操作时，会停下来要求用户确认许可。这对于安全性至关重要，但如果频繁弹出确认，会打断工作流。本章介绍三种管理权限的方式。

## 权限模式概述

当你开启 **"accept edits on"（自动接受编辑）** 模式时，Claude Code 只会自动修改和保存代码文件。但当它需要执行终端命令（如 `npm install`、`mkdir`、`git push`）、读取环境变量或发起网络请求时，依然会停下来强制要求你同意。

## 方法一：dangerously-skip-permissions

```bash
claude --dangerously-skip-permissions
```

跳过所有权限检查，Claude Code 执行任何操作都不会询问。

::: callout-caution
## 风险最高

此方法意味着 Claude Code 可以不受限制地执行任何命令，包括删除文件、推送代码等危险操作。仅在你完全信任当前任务且理解风险的情况下使用。
:::

## 方法二：Auto 模式（推荐）

```bash
claude --permission-mode auto
```

Auto 模式使用一个**后台 AI 分类器**来代替你做决定：

- **90% 以上的常规安全命令**（如 `ls`、新建文件、跑测试代码）会**自动同意并执行**
- 只有当它试图执行真正危险的操作（比如删除数据库、推送包含密码的代码）时，才会停下来问你

既保证了心流不被打断，又防止了系统崩溃。

::: callout-note
## 模型兼容性

Auto 模式需要使用 Claude 官方模型（Sonnet/Opus）才能正常工作。如果使用 GLM 等第三方模型，Auto 模式可能不可用。
:::

## 方法三：settings.json 白名单

在 `.claude/settings.json`（全局）或 `.claude/settings.local.json`（项目级）中配置白名单，白名单里的命令不需要询问用户许可。

### 白名单的自动添加

每次 Claude Code 询问是否允许某个操作时，如果选择 **"Yes, and don't ask again for ..."**，Claude Code 会自动在 `.claude/settings.local.json` 的白名单里添加这个命令。

### 手动配置示例

```json
{
  "permissions": {
    "allow": [
      "Bash(ls:*)",
      "Bash(mkdir:*)",
      "mcp__stata-mcp__stata_run_selection",
      "mcp__stata-mcp__stata_run_file"
    ]
  }
}
```

如果不确认添加某个命令是否有风险，可以先问问 AI。

## 三种方法对比

| 方法 | 安全性 | 便利性 | 适用场景 |
|------|--------|--------|----------|
| `--dangerously-skip-permissions` | 最低 | 最高 | 快速实验，不涉及敏感操作 |
| `--permission-mode auto` | 较高 | 高 | 日常使用（推荐） |
| settings.json 白名单 | 最高 | 需要配置 | 团队协作、规范化的工作流 |

::: callout-tip
## 实用建议

对于使用 Stata MCP 进行数据处理的场景，推荐在 `settings.json` 中将 `stata_run_selection` 和 `stata_run_file` 加入白名单，这样 AI 调用 Stata 时不会反复询问权限。
:::
