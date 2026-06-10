# 失语症特征诊断（features.py）

`/diagnose2` 背后的方法说明：**让 LLM 逐条识别语言学特征 → 加权打分 → 判是否失语 + 严重度**。
本文档记录它解决什么问题、怎么做、验证到什么程度、以及已知边界。

---

## 1. 为什么要做（替代了什么）

系统原有两条诊断路，用真实语料（AphasiaBank 普通话 JiangLin 语料）一测，**都有硬伤**：

| 旧实现 | 问题（2026-06 实测） |
|---|---|
| `diagnose2`：BERT 困惑度 | **方向相反**。失语患者爱重复（"踢踢破了"），重复字好预测 → 困惑度反而**低**；健康人口语稀词 → 困惑度高。患者 median 73 < 健康 203，AUC < 0.5（比瞎猜还差）。 |
| `diagnose1`：大模型一锤子判类型+严重度 | **过度诊断**——误诊一半健康人（特异度仅 43%）；**严重度恒"中度"**不分级；**类型几乎恒"Broca"**（8 个有金标准的患者只对 1，还是蒙的）。 |

根因相同：**笼统判断 / 困惑度，在信息不足或方向错的指标上必然失败。** 改用结构化的"特征分解"。

---

## 2. 方法

参照 HuggingFace `NathanRoll/tab`（TAB，基于临床 APROCSA 量表）的思路，**本地化到中文口语**：

```
医患对话 → LLM(DeepSeek-V3) 逐条判 13 个二值语言学特征(0/1)
         → 判别力加权求和 = 严重度分(连续)
         → 分 ≥ 2.3 判失语；分档(轻/中/重)；点亮特征按权重降序作"证据"
```

- **13 个特征**（`FEATURES`）：从 TAB 的 19 条本地化——删了中文几乎没有的"词缀省略"、经 ASR 会丢失的"音位错语 / conduite d'approche"。定义+中文例子在 `prompt_features.txt`。
- **权重**（`FEATURE_WEIGHTS`）：每个特征"患者点亮率 − 对照点亮率"（判别力），负的归零。在语料上标定。
- **阈值**（`APHASIA_THRESHOLD = 2.3`）：对照分布约 90 分位，平衡查全/特异。
- **温度 0**：诊断要可复现，`siliconflow.text_conversation(temperature=0)`。

> 与 TAB 的关系：**借了"特征分解"范式 + APROCSA 临床框架**；但提示词、13 特征、权重、阈值全是针对中文口语场景重做并用真实语料验证的。

---

## 3. 验证结果

| 阶段 | 结论 |
|---|---|
| 分类（26 患者 vs 96 对照） | **AUC 0.955**；阈值 2.3 时**查全 88% / 特异 91%**（对比旧 diagnose1 的 86% / **43%**——查全持平、特异度翻倍） |
| 聚合方案（留一交叉验证） | 判别加权分 LOO-CV AUC 0.962（不过拟合）；"重述/自我修正"在 57% 健康人也点亮，已降权 |
| 严重度（≈11 个带 WAB-AQ 的患者） | 加权分与 WAB-AQ **负相关 −0.69 ~ −0.90**（干净子集），说明分跟着严重度走 |
| 漏诊分析 | 漏掉的患者都是**最轻症**（WAB-AQ 88~93，逼近正常线），合理 |

复现：`set -a; source ../.env; set +a; .venv/bin/python validate_features.py all`（结果缓存 `features_cache.json`）；
聚合对比 `rescore.py`；严重度相关 `p3_severity.py`；离线回归 `pytest test_features_regression.py`（锁 AUC ≥ 0.9）。

---

## 4. 依赖

- **需要**：`SILICONFLOW_API_KEY`（DeepSeek-V3，本就用于 repair/翻译）+ `prompt_features.txt`。
- **不需要**：torch / transformers / BERT 模型（困惑度路已整体删除，部署轻量化）。

---

## 5. 已知边界（暂留 / 待办）

1. **不做类型分类（已实测证伪"从对话特征分型"这条路）**。Broca/Wernicke/Anomic… 由 3 个维度定义（流畅度、**听理解**、**复述**），后两者**不在自发对话里**，光靠特征拿不到。完整分型需新增结构化子任务（理解/复述/命名，可做成"套题"），把分数喂进 WAB 决策树。

   **3 类分型可行性实验（2026-06，负结果存档，省得重走）**：从英文 AphasiaBank 平衡采样 ~170 个带 WAB 类型的 PWA（Broca/Anomic/Wernicke），跑同一套 13 特征抽取 → 朴素贝叶斯。
   - **英文内部留一交叉验证仅 58%**（瞎猜 33%）：Broca/Anomic 勉强（65%/67%），**Wernicke 仅 42%、半数错判成 Broca**——"新词""句法错乱"对 Broca/Wernicke 都高，不判别。
   - **跨语言迁移到中文 30%（≈瞎猜）**：中文 anomic 病人大批错判成 Broca，因中英文特征"点亮率基线"不一致，贝叶斯学的英文基线套不上中文向量。
   - **直接用中文训也不行**：中文带类型样本只有 Anomic 21 / **Broca 1 / Wernicke 1**，单样本无法训练或验证；且 Mandarin AphasiaBank 天生以 anomia 为主，缺类型多样性。
   - **结论**：连续言语特征**唯一稳的维度是流畅度**（短而简化+虚词省略 → Broca 高），故最多支持"**非流畅(Broca型) vs 流畅**"的 2 分；Wernicke vs Anomic（都流畅）不管中英文都分不开（信息不在对话里）。可复现：`prompt_features_en.txt` + `type_extract_en.py` + `type_classify.py`。
   - **正路**：类型靠结构化子任务测量，或自攒平衡的中文临床分型数据；别再从对话特征里硬榨细类型。
2. **严重度分档暂定**。仅 ≈8 个 WAB-AQ 样本标定，连续 `score` 比档位可靠；拿到更多 WAB-AQ 应重标 `SEVERITY_BANDS`。
3. **阈值在干净转写上标定**。生产若走 ASR（带识别噪声），`APHASIA_THRESHOLD` 需重新标定——故意做成文件顶部可见常量。
4. **特征抽取器本身未对人工金标准验证**。已验证"分能区分两组"，但"LLM 判的每个特征对不对"只用 CLAN 记号做过部分代理；可用英文 APROCSA 专家评分数据补这块。
5. **数据集不进 git**（临床数据，受 AphasiaBank 协议约束），路径用 `CORPUS_PATH` 覆盖。

---

## 6. 相关文件

| 文件 | 作用 |
|---|---|
| `features.py` | 特征抽取 + 加权 + `diagnose()` 编排（线上路径） |
| `prompt_features.txt` | 13 特征的中文定义+示例 |
| `chat_corpus.py` | 解析 AphasiaBank `.cha` 语料 |
| `validate_features.py` / `rescore.py` / `p3_severity.py` | 离线验证/标定脚本 |
| `test_features_regression.py` | 离线回归测试（聚合逻辑 + 缓存 AUC） |
