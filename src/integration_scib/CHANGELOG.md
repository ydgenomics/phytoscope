# CHANGELOG — src/integration_scib

> 记录 `integration_scib` 下所有脚本的变更历史。

---

## [v0.2] — 2026-07-09

### 变更内容

1. 为所有脚本添加统一的运行时间记录（`[TIME] 总运行时间: X.XXX h`）
2. 为所有脚本添加各自分组的 UMAP PNG 保存，命名格式为 `{method}_{key}.png`
3. UMAP 图取消独立 legend，标签直接标在图上

### 修改详情

| 脚本 | 计时 | PNG 保存 | Legend 修改 |
| ---- | :--: | :------: | :---------: |
| `BBKNNR_integration.R` | ✅ | ✅ 保存 `{method_tag}_{key}.png` | ✅ `DimPlot + NoLegend()`，PDF 和 PNG 均去掉 legend，标签标在图上 |
| `rliger.INMF_integration.R` | ✅ | ✅ 同上 | ✅ 同上 |
| `SCTransform.CCA_integration.R` | ✅ | ✅ 同上 | ✅ 同上 |
| `SCTransform.harmony_integration.R` | ✅ | ✅ 同上 | ✅ 同上 |
| `harmony_integration.py` | ✅ | ✅ `harmony_{key}.png` | ✅ `legend_loc='right margin'` → `'on data'` |
| `scVI_integration.py` | ✅ | ✅ `scVI_{key}.png` | ✅ 同上 |
| `unintegration.py` | ✅ | ✅ `unintegrated_{key}.png` | ⏭️ 原已是 `'on data'` |
| `scIB.py` | ⏭️ 已有 | ⏭️ 不适用 | ⏭️ 不适用 |

### PNG 输出示例

| 脚本 | method_tag | 生成文件示例 |
| ---- | ---------- | ------------ |
| BBKNNR | 从 `out_rds` 自动提取 | `BBKNNR_biosample.png`, `BBKNNR_metaneighbor.png` |
| rliger.INMF | 同上 | `rliger.INMF_biosample.png`, `rliger.INMF_celltype.png` |
| SCTransform.CCA | 同上 | `SCTransform.CCA_biosample.png` |
| SCTransform.harmony | 同上 | `SCTransform.harmony_biosample.png` |
| harmony | `"harmony"` | `harmony_biosample.png` |
| scVI | `"scVI"` | `scVI_biosample.png` |
| unintegrated | `"unintegrated"` | `unintegrated_biosample.png` |

### 输出格式

所有脚本统一为：

```text
[TIME] 总运行时间: 1.235 h
```

---

## [v0.1] — 初始版本

- 7 个整合方法脚本 + 1 个 scIB 评估脚本，支持多方法整合与基准评测
