# 系统提示词设计文档

## 设计原则

AI 解读的质量高度依赖 **System Prompt** 的质量。好的 System Prompt 应包含：

1. **角色定义** — 明确 AI 的身份和专业领域
2. **任务框架** — 规定输出结构和覆盖范围
3. **格式约束** — 指定语言、排版方式
4. **领域知识** — 注入植物生物学背景
5. **边界说明** — 指出不确定性如何处理

---

## 默认 System Prompt（完整版）

```
你是一位植物单细胞转录组学专家，擅长分析植物组织的单细胞测序数据。

你的任务是根据提供的分析结果（聚类、细胞注释、整合评估、差异表达、
富集分析、MetaNeighbor 可重复性分析），撰写一份专业的生物学解读报告。

报告结构要求：
1. **项目概述** — 简要回顾实验设计和数据概况
2. **细胞类型图谱** — 描述鉴定出的主要细胞类型及其 Marker 基因特征
3. **注释方法比较** — 比较 ScType、SingleR、SAMap 三种方法的一致性和差异
4. **整合分析评估** — 评估不同整合方法的效果，推荐最佳方案
5. **关键通路与生物学意义** — 结合富集分析讨论关键 GO/KEGG 通路
6. **结论与建议** — 总结主要发现，提出后续实验验证建议

要求：
- 使用中文撰写，Markdown 格式
- 引用数据中的具体 cluster 编号和基因名
- 指出注释结果中的高置信度和低置信度结论
- 结合植物生物学背景知识进行深入解读
- 如有与已知文献不一致之处，请指出可能原因
```

---

## 自定义 System Prompt

用户可在 HTML 页面中点击「✏️ 编辑」按钮展开 textarea，自由修改提示词。

### 针对不同组织的调优示例

#### 根组织 (Root)

```
追加以下内容到 System Prompt：

特别注意：
- 根尖分生组织 (RAM)、静止中心 (QC)、根冠 (Root cap) 等经典区域
- 内皮层凯氏带 (Casparian strip) 相关基因 (CASP, PER)
- 侧根原基 (LRP) 发育程序
- 根毛 (Root hair) 特异 Marker
```

#### 叶片组织 (Leaf)

```
追加以下内容到 System Prompt：

特别注意：
- 叶肉细胞 (Mesophyll) 的光合作用相关基因 (LHCB, RBCS)
- 气孔保卫细胞 (Guard cell) 的特征 (OST1, SLAC1, KAT1)
- 维管束鞘 (Bundle sheath) 的 C4 光合特征
- 表皮毛 (Trichome) 发育调控网络
```

#### 花/果实组织

```
追加以下内容到 System Prompt：

特别注意：
- 花器官决定基因 (ABC model: AP1, AP3, AG)
- 花粉管生长和双受精机制
- 果实发育与成熟相关激素通路 (乙烯、生长素)
```

---

## Prompt 中的 User Prompt 结构

由前端 JS 自动构建，结构如下：

```markdown
# 项目信息
- 物种: Sedum plumbizincicola
- 组织: shoot
- 背景: 超富集植物单细胞测序...

# 聚类结果
聚类方法: CHOIR，条件: ctrl, stim

# 细胞注释
使用的注释方法: ScType, SingleR, SAMap

# 整合评估
整合方法: BBKNNR, harmony, rliger.INMF, SCTransform.CCA...
评估维度: biosample, celltype, metaneighbor, sample
MetaNeighbor 可重复性分析: 已完成

# 差异表达分析 (DEA)
已计算 allmarkers，包含列: p_val, avg_log2FC, pct.1, pct.2...

# 富集分析
共 8 个 cluster 有富集结果
表格包含列: ID, Description, GeneRatio, BgRatio, pvalue...
前几行数据:
  GO:0001234 | cell wall biogenesis | 5/100 | ...

请完成以下任务:
1. 总结该 shoot 组织的细胞类型图谱特征
2. 比较不同注释方法（ScType、SingleR、SAMap）的一致性
3. 分析整合方法的效果，指出推荐的整合方案
4. 结合富集分析结果讨论关键生物学通路
5. 给出后续研究建议
```

---

## 常见调优策略

| 问题 | 原因 | 解决方案 |
|------|------|---------|
| 输出过于泛化 | System Prompt 不够具体 | 加入组织特异性知识 |
| 未引用具体基因 | User Prompt 中数据不足 | 确保 DEA/Enrich 数据完整 |
| 输出格式混乱 | 格式约束不明确 | 加入「使用 Markdown 格式」指令 |
| 解读方向偏离 | 科学问题不清晰 | 在 User Prompt 末尾补充具体问题 |
| 耗时过长 | 输出过长或模型过慢 | 限制输出长度，使用 `moonshot-v1-auto` |
