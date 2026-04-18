## Stata 数据处理规范

- 通过 Stata-mcp 调用 Stata，不要用命令行。
- 原始数据在 `data/raw/` 目录下，不要修改或覆盖；清洗过程中以及清洗后的数据存入 `data/processed/`
- 代码放在 `code/`
- 说明文档放在 `file/`
- Stata MCP 运行在 Windows 端，必须使用 Windows 路径格式（`C:/Users/...`），不能用 WSL 的 `/mnt/c/...` 格式，否则报 `r(601) file not found`


## 如果没有连接 Stata MCP，按以下要求调用 Stata。如果 Stata MCP 已连接则忽略以下内容。

- 路径：`D:\stata18\StataMP-64.exe`
- 批量运行：`"/d/stata18/StataMP-64.exe" /e do "script.do"`
- 运行前先 cd 到 .do 文件所在目录，日志自动生成到该目录，文件名为 `script.log`
- 代码错误检测
  - Stata 退出码不可靠，应检查 .log 文件
  - 若 .log 文件含 `r(` 或缺少 `end of do-file`，说明有代码错误