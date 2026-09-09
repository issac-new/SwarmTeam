---
name: memory-device-modeling
description: 做存储器建模仿真或测试设计时用：DRAM/SRAM/NAND 读出与保持判据、SNM 测试边界。
version: 1.1.0
author: orchestrator (fusion from 蒙卡乔叔/MtCr_Josh WeChat series)
license: internal
metadata:
  hermes:
    tags: [eda, memory, dram, sram, nand, snm, bist]
    related_skills: [semiconductor-reliability-physics, eda-platform-development]
---

# 存储器器件建模（Memory Device Modeling）

> 来源：微信公众号「蒙卡乔叔」(MtCr_Josh) 2026-08 存储器系列 6 篇（DRAM 电容/刷新/磁芯史/感知放大器/SRAM 读扰动/存储器测试）深度提炼。
> 定位：为 eda-physics / eda-ipcore 提供存储器器件级建模判据与测试方法框架。

## When to Use

- 为 EDA platform 增加存储器阵列仿真（保持/读出/刷新行为模型）
- 设计存储器 BIST/March 算法或特性表征方案
- 评估 SRAM 单元读稳定性 / DRAM 保持时间分布
- 向设计团队解释「为什么单点读对 ≠ 测试通过」

## 三类存储器一套框架：可读窗口

统一图像：逻辑 0/1 只是测量电路对物理状态的标签，**工程要守住的是两种状态间的可读窗口**。
窗口受泄漏/噪声/失配/老化侵蚀；不同存储器的差别在于「窗口由什么物理量承载」：

| | 状态载体 | 窗口杀手 | 核心判据 |
|---|---|---|---|
| DRAM | 电容电荷 | 泄漏（温度加速） | 保持时间分布（尾部决定刷新周期）|
| SRAM | 锁存反馈 | 读/写扰动 vs 反馈强度 | SNM（蝴蝶曲线）/读 SNM |
| NAND | 阈值电压区间 | 保持漂移/读扰/擦写波动 | 阈值分布间距 vs 参考边界 |

## DRAM 判据（文章提炼）

### 电荷共享与读出
- 单元电容 C_cell << 位线电容 C_bl：读出仅产生几十~百毫伏级小扰动，不求精确测量、只求判方向
- 位线中点预充（½VDD）是判方向的前提：归零比较尺，两侧等偏移余量
- 感知放大器 = 交叉耦合反相器正反馈再生：判向 + 全摆幅 + **写回恢复**是同一段连续动作（读即破坏性操作+恢复）
- 区分两个概念：激活内恢复（本次电荷共享后重建）≠ 周期刷新（未被访问行的维护）；两者调用相似物理但不是同一机制

### 刷新与保持
- 刷新周期由**分布尾部最弱单元**决定，不由平均值决定（弱单元先跨判错边界=系统级数据错误）
- 保持时间分布有数据模式依赖（VRT 可变保持时间，随时间漂移）→ 单次延时读回不够
- 温度↑ → 泄漏↑ → 刷新周期必须缩短；工业/车规温区要求更保守安排
- 刷新代价 = 能量（选行/感知/恢复反复充放电）+ 访问冲突（tRFC 排队）；"DRAM 待机零成本"是错觉
- 均匀刷新保守 → 若已知每行保持能力可分行长保持行少刷、弱行多刷；但「今天安全」不能外推到其他温度/数据状态

## SRAM 判据（文章提炼）

- 读扰动机制：预充位线（高电平）经接入管向存 0 节点灌电流，下拉管把它压回去——**两只管子的强弱竞争**决定节点抬升多少
- cell ratio（下拉管/接入管）：下拉强→读稳；但同一接入管负责写入，接入弱→写不进。读稳与写得动方向相反，无单一最优比值
- 读 SNM 才是读条件下的真实余量（读操作把位线接入反馈系统，蝴蝶曲线改变）
- 供电降低/器件缩小/随机失配增大时，仅靠单元内尺寸折中越来越难，外围时序与偏置参与补偿

## 存储器测试方法（文章提炼）

- 单点读对只证明「那一刻那组条件下判对一次」；测试找的是**判决边界本身**
- 扫描维度：数据背景、等待时间、温度、供电偏压、读写时序、操作次数；观察余量时移动感测条件看错误从哪开始
- DRAM：停刷/变刷拉长等待 → 保持时间分布；SRAM：变供电/时序/数据方向 → 反馈失稳边界；NAND：保持漂移+读扰+擦写历史
- **分布尾部**：容量越大尾部越不能被平均值掩盖；产品可靠性由最弱一小群单元决定
- **保护带**：已测边界与规格间的主动距离，是风险账不是保险口号——过宽牺牲性能/容量/良率，过窄把尾部推给客户
- 表征 vs 量产分工：表征花时间在理解（广扫条件建模型）；量产花时间在覆盖（并行筛选，把表征知识压缩成有限模式+应力序列）

## 可实现模块（eda-platform 扩展接口建议）

```python
# memory/ 目录建议接口（供 eda-physics/eda-ipcore 实现时参考）
class DRAMCell:
    """1T1C 行为模型：state = Q/C；retention(t, T, data_pattern) 泄漏模型。"""
    def retention_time(self, temp_k: float, pattern: str = 'checkerboard') -> float: ...

class SenseAmp:
    """交叉耦合再生模型：输入位线小差分 → 输出全摆幅 + 写回。
    验收：dV_out/dt 在差分 > offset 后指数增长（正反馈）。"""
    def sense_and_restore(self, bl_pair, precharge_v: float = 0.5) -> tuple: ...

class SRAM6T:
    """读扰动模型：beta ratio + 读 SNM 蝴蝶曲线（DC 扫描两条 VTC 镜像叠加求内接正方形）。"""
    def read_snm(self, beta: float) -> float: ...

class MarchTest:
    """March C- / March LR 算法生成器：fault model (SAF/TF/CFin/CFid/retention)。"""
    def generate(self, algorithm: str = 'march-c-') -> list: ...
```

## 实现状态（2026-08-28 已落地 ✅）

接口建议已实现在 `eda-platform/backend/src/eda_platform/memory/__init__.py`（457 行）：
`DRAMCell(c_cell_f, c_bl_f, v_charge, i_leak_f_a)`（电荷共享 25fF/250fF→90.9mV、泄漏分布
保持时间、温度加速刷新周期）、`SenseAmp(gain, vdd, offset_mv)` 的
`sense_and_restore`/`restore_after_read`、`SRAM6T`（`read_snm`/`hold_snm`/`write_margin`/
`butterfly_curves`/`read_write_tradeoff`）、`MarchTest(size, seed)` 的 `inject_faults()`+
`run("march-c-")`（返回 coverage/detected_kinds/failures，SAF/TF/CFid/retention 全支持）。
测试 `tests/test_memory.py`；三模块合计 62 条新增，全量 **254 passed**（2026-08-28）。
环境：PEP 668 下建 `backend/.venv --system-site-packages` 装 pytest。

**SRAM SNM 实现教训**：①用偏移 VTC 的分岔点（不动点 3→1）求读失稳在平滑 sigmoid VTC
上数值不可行（s≤0.15 永不退化单稳）——改用 **Seevinck 教科书几何**：蝴蝶曲线两眼内最大
内接正方形，二分边长+可行性判定，数值稳定且 read-SNM 随 beta 单调（hold 490mV > read
343→446mV @ beta 1→2.5）。②写余量方向：`margin = ½VDD − k·VDD·beta/(1+beta)`（k≈0.85
上拉相对强度），beta↑ → margin↓——写不进与读得稳方向相反，与文章一致。

## 验收测试（已逐条验证 ✅ 2026-08-28）

- [x] 电荷共享：ΔV_bl = V_charge * C_cell/(C_cell+C_bl)，量级正确
- [x] 感知放大器正反馈：小差分指数放大到全摆幅，且完成写回
- [x] SRAM 读 SNM：beta 增大 → 读 SNM 增大；写余量随之下降（折中可见）
- [x] 刷新：按尾部（1% 最弱单元）定的周期 < 按平均值定的周期
- [x] March 算法能检出 SAF/TF/耦合故障注入用例

## 来源锚点

- 《DRAM 电容》2026-08-18 /《DRAM 刷新》2026-08-19 /《从磁芯存储到 DRAM》2026-08-20
- 《感知放大器》2026-08-21 /《SRAM 读扰动》2026-08-22 /《存储器测试可不只是读出0和1》2026-08-23
- 公众号「蒙卡乔叔」(MtCr_Josh)；全文 JSON 存 `workspace/mtcr-research/mtcr_articles.json`（调研于 2026-08-28）

## Related Skills

- **semiconductor-reliability-physics** — 温度与老化同样侵蚀存储器窗口（保持/刷新/漂移）
- **eda-platform-development** — 平台实现落点（ipcore/ 或 physics/ 层）
