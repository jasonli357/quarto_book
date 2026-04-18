# Claude Code 协同 Stata：环境配置与应用实践

本项目是一本基于 [Quarto Book](https://quarto.org/) 编写的在线电子手册，介绍如何使用 Claude Code 配合 Stata 进行数据处理。

## 内容简介

- **Stata 环境配置**：在 CLAUDE.md 中配置 Stata、安装 Stata MCP
- **Claude Code 交互技巧**：执行权限控制、技能包管理、常用斜杠命令
- **数据处理实践**：清洗 CSMAR 企业财务数据
- **Skill 创建与复用**：将数据处理流程打包为可复用的 Skill

在线阅读：<https://jasonli357.github.io/quarto_book/>

## 项目结构

```
_quarto.yml        # 全局配置
index.qmd          # 首页
body/              # 章节文件
styles.css         # 自定义样式
docs/              # Quarto 渲染输出（自动生成）
file/              # 参考资料（不参与编译）
```
