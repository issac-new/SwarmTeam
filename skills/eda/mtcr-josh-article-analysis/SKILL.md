---
name: mtcr-josh-article-analysis
description: 分析蒙卡乔叔(MtCr_Josh)公众号半导体文章并融合进 EDA 集群时用：抓取管线+方法论+映射表。
version: 1.0.0
author: orchestrator (fusion methodology 2026-08-28)
license: internal
metadata:
  hermes:
    tags: [research, wechat, eda, fusion-methodology, mtcr-josh]
    related_skills: [wechat-article-research, open-source-skill-fusion]
---

# MtCr_Josh（蒙卡乔叔）文章分析与融合方法论

> 2026-08-28 全量调研的管线、发现与融合方法论沉淀。文章数据：`workspace/mtcr-research/mtcr_articles.json`（10 篇 OK / 18,845 字符）。
> 该账号定位：半导体器件与可靠性科普-工程桥梁（未认证个人订阅号，微信号 MtCr_Josh，显示名蒙卡乔叔）。

## 账号情报（2026-08-28 实测）

- 搜狗 type=1 无收录（未认证号）；type=2 文章搜索是唯一发现通道
- 时间线：2026-03-29 首发《晶体管、芯片、摩尔定律》（**已被发布者删除**，无法抓取）→ 2026-08-14 起日更系列
- 现存 10 篇全部为「物理机制 → 工程权衡 → 设计边界」论证范式，每篇文末有「点击获取完整PPT资源」钩子
- 搜狗索引深度有限（每查询页深 ~1 页即重复）；多组关键词轮查（可靠性/存储器/芯片/半导体）共挖出 10 篇唯一文章
- 索引面复查（2026-08-28）：用可靠性/存储器/寄生/磁芯/半导体等 ≥8 组关键词轮查 + name-search 双通道，新增发现已枯竭（连续 3 组查询无新条目），判定 10 篇≈当前全量可得

## 抓取管线（复用 wechat-article-research skill 的防 403 纪律）

1. `type=2&query=<wxid 或显示名>` 发现（两个 query 都跑，结果集不同！）
2. 标题去重后逐篇 `/link?url=` 解析：`time.sleep(10)` 间隔 + 等待跳转 `mp.weixin.qq.com`（最多 12s，失败重试 1 次）
3. `#js_content` 提取；`status=ok` 门槛 content>500 字符
4. 失败文章先用**标题重搜**、再用**关键词子查询**重试（skill Step 3）
5. 「该内容已被发布者删除」= 终态，如实记录不做无谓重试
6. 多次搜索轮查补全 → 数据落盘 JSON（title/pub/content/len/status）+ browser daemon cwd 拷回真实 workspace（daemon 的相对路径写文件会落在它自己的 cache workspace！）

## 方法论：把科普文章变成团队能力（本次实战检验）

### 三步转化
1. **深读全文**（不摘要工具代替）：提取每篇的「机制→判据→权衡→边界」链
2. **判据化**：把叙述转成可执行规则——「刷新周期由分布尾部最弱单元决定」→「算法按 1% 尾部定周期，非平均值」
3. **接口化**：每个主题给出 Python 接口建议 + 验收测试清单（对照平台现有模块），让 worker 直接可实现

### 映射表（文章 → EDA team 归属）

| 文章 | 归属 profile | 落地 skill |
|------|-------------|-----------|
| TDDB / 热载流子 / 自热 | eda-physics（老化建模）+ eda-ai（老化预测模型） | semiconductor-reliability-physics |
| DRAM 电容 / 刷新 / 磁芯史 | eda-physics（器件模型）| memory-device-modeling |
| 感知放大器 / SRAM 读扰动 | eda-physics + eda-ipcore（存储 IP）| memory-device-modeling |
| 存储器测试 | eda-ipcore（BIST/March）| memory-device-modeling |
| 寄生参数提取 | eda-toolchain | parasitic-extraction-methods |

### 融合纪律（沿用 open-source-skill-fusion 蓝军教训）

- gap 判定双向查证：宣称「平台缺 X」前先 grep 平台源码（本轮实证：可靠性/存储器/BIST 全缺、FRW 已有——寄生文章定位为「增强」而非「新建」）
- 文章是二级来源：判据引入时标注机制归属（如 BTI 文章未细讲，只作对照表占位，不冒充已调研）
- 每个数字可追溯：文章数、字符数、时间线全部来自抓取 JSON 与搜索记录

## 本轮调研统计（可追溯）

- 发现通道：wxid 搜索 1 页 + 显示名搜索 2 页 + 4 组关键词轮查（全部记录在 mtcr-research/）
- 结果：12 entries → 去重 10 篇 OK + 1 篇已删除（晶体管/摩尔定律，2026-03-29）+ 1 条他号混入（ProAVLAsia，排除）
- 总字符：18,845（10 篇 OK）
- 新建 skill：3 个领域 skill（reliability / memory / parasitic）+ 本方法论 skill
- 平台源码对照：`grep -ril "tddb|hot.carrier|self.heating"` 等 → 零命中（真 gap）；`physics/frw.py` 已有 FRW 提取（增强项）

## Related Skills

- **wechat-article-research** — 通用抓取管线（Sogou 发现/防 403/标题重搜）
- **open-source-skill-fusion** — 融合纪律（双向查证/数字实测/可见性验证）
- **semiconductor-reliability-physics / memory-device-modeling / parasitic-extraction-methods** — 本轮三大产出
