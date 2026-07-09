# CHANGELOG — src/integration_scib

> 记录 `integration_scib` 下所有脚本的变更历史。

---

## [v0.2] — 2026-07-09

### 变更内容

为所有脚本添加统一的运行时间记录（`[TIME] 总运行时间: X.XXX h`），便于监控各整合方法的耗时。

### 修改详情

| 脚本 | 语言 | 修改方式 |
| ---- | :--: | -------- |
| `BBKNNR_integration.R` | R | 参数解析后加 `start_time <- proc.time()`，脚本末尾加 elapsed 打印 |
| `rliger.INMF_integration.R` | R | 同上 |
| `SCTransform.CCA_integration.R` | R | 同上 |
| `SCTransform.harmony_integration.R` | R | 同上 |
| `harmony_integration.py` | Python | import 区加 `import time`，函数入口加 `start = time.time()`，末尾加 `click.echo(...)` |
| `scVI_integration.py` | Python | 同上 |
| `unintegration.py` | Python | 同上 |
| `scIB.py` | Python | **已有**计时逻辑（`import time; start = time.time()` → `end = time.time()` → `print(f"Time: ... min ... sec")`），未做修改 |

### 输出格式

所有脚本统一为：

```text
[TIME] 总运行时间: 1.235 h
```

---

## [v0.1] — 初始版本

- 7 个整合方法脚本 + 1 个 scIB 评估脚本，支持多方法整合与基准评测
