# 执行权限控制 {#sec-permissions}

Claude Code 在执行某些操作时，会停下来要求用户确认许可。这对于安全性至关重要，但如果频繁弹出确认，会打断工作流。本章介绍三种管理权限的方式。

## 权限模式概述

当你按开启 **"accept edits on"（自动接受编辑）** 模式时，Claude Code 只会自动修改和保存代码文件。但当它需要执行终端命令（如 `npm install`、`mkdir`、`git push`）、读取环境变量或发起网络请求时，依然会停下来征求你同意。

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

既保证了工作不被打断，又防止了系统崩溃。

::: callout-note
## 模型兼容性

Auto 模式需要使用 Claude 官方模型（Sonnet/Opus）才能正常工作。如果使用 GLM 等第三方模型，Auto 模式可能不可用。
:::

## 方法三：settings.json 白名单

在 `.claude/settings.json` 或 `.claude/settings.local.json`中配置白名单，白名单里的命令不需要询问用户许可。

::: callout-note
## 补充
`.claude/settings.json` 和 `.claude/settings.local.json` 的设计意图不同 —— `settings.json` 是团队共享的配置，`settings.local.json` 是个人本地的配置。只是当项目只有你一个人用、也不上传时，这个区分就无所谓了。 

 一般来说，如果项目要上传到 GitHub，应在 .gitignore 中添加 `.claude/settings.local.json`，避免将个人配置（如自定义权限、API 密钥等）提交到仓库。`.claude/settings.json` 则作为项目共享配置随仓库一起上传。如果项目不上传到 GitHub，两者在使用效果上没有区别。
:::

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

如果不确认添加某个命令是否有风险，可以在 AI 征求某个命令的许可之后，马上用 `/btw` 问问 AI。
