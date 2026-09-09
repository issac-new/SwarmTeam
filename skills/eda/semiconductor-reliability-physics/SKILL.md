---
name: semiconductor-reliability-physics
description: 做器件老化建模、可靠性仿真或寿命评估时用：TDDB/HCI/BTI/自热判据与外推边界。
version: 1.1.0
author: orchestrator (fusion from 蒙卡乔叔/MtCr_Josh WeChat series)
license: internal
metadata:
  hermes:
    tags: [eda, reliability, tddb, hci, bti, self-heating, weibull]
    related_skills: [eda-platform-development, memory-device-modeling]
---

# 半导体可靠性物理（Reliability Physics）

> 来源：微信公众号「蒙卡乔叔」(MtCr_Josh) 2026-08 可靠性系列 3 篇（TDDB/热载流子/自热）深度提炼，适配 Hermes EDA team。
> 定位：为 eda-physics / eda-ai 提供老化建模的物理判据与仿真实现边界。

## When to Use

- 为 EDA platform 增加器件老化/可靠性仿真模块
- 判断某项退化该用哪个机制模型（HCI vs BTI vs TDDB vs 自热）
- 设计或审查加速寿命测试及外推合理性
- 评估先进工艺（FinFET/GAA/SOI）热敏感性对时序/寿命的影响

## 四机制对照表（工程对策不能混用的根源）

| 机制 | 触发条件 | 损伤位置 | 电学表现 | 对策抓手 |
|------|---------|---------|---------|---------|
| HCI 热载流子 | 漏端横向高场 + 开关活动 | 沟道靠漏端局部界面/邻近介质 | Vth 漂移、跨导下降、延迟增加 | 降漏端场峰（LDD/间隔层）、控制偏置时间 |
| BTI 偏压温度不稳 | 栅偏压占空比 + 温度 | 栅介质陷阱占据/生成 | Vth 漂移（可恢复性） | 管理栅偏置占空比、温度 |
| TDDB 介质击穿 | 电场+时间→缺陷贯通 | 栅介质体 | 漏电上升→软/硬击穿 | 介质厚度/材料、场强外推 |
| SHE 自热 | 沟道耗散→局部温升 | 全器件（热路径依赖几何） | 迁移率↓/漏电↑、加速其他三者 | 散热路径/版图热耦合管理 |

关键纪律：真实芯片多机制并存，模型必须分别建立——一项优化可能只是把主导风险推给另一机制。
HCI 的"热"指高能非平衡载流子分布尾部，≠晶格温度；SHE 才是真实温升。

## 核心判据（文章提炼）

### TDDB
- 失效 = 缺陷生成（应力演化）+ 渗流贯通（percolation）双过程；软/硬击穿是同一缺陷演化的不同程度
- 面积缩放：测试结构越小越不易失效，外推到大器件/阵列必须做面积尺度处理
- 外推边界：加速应力过高会激活使用条件不占主导的机制 → 测试区与使用区物理链断裂，拟合再整齐也无效；用多档电压/温度/面积验证机制连续性
- 寿命结论 = 物理模型（应力→时间尺度）+ 统计分布（Weibull，含未失效样品的截尾信息）两部分共同交代
- 面积/晶圆位置/批次斜率异常群体 → 指向污染、边缘场或介质栈另一层缺陷，需单独处理

### HCI
- 损伤由少数高能载流子决定，不看平均电流；电流最大 ≠ 损伤最重
- 最严苛工作点需扫描栅压×漏压组合寻找
- 损伤空间局部（漏端）；翻转工作方向/交流负载后退化分布与恢复表现不同
- 温度关系非单调（声子散射竞争），不同器件/偏置/温区表观趋势可相反——先定主导机制再谈加速因子
- 失效先表现为规格失守（时序/增益/匹配），远早于物理短路

### SHE（自热）
- 瞬态热阻 ≠ 稳态热阻×常数：纳秒脉冲/微秒突发/长期满载温度响应不同（有效热容随扩散体积变化）
- 热敏感序：体硅 < FinFET < GAA 多层堆叠（内层片热要穿更多界面）；SOI 埋氧阻挡向下热流
- 温度传感器读数 ≠ 器件结温（隔硅/互连/封装读平均值，瞬态峰值已过去）
- 温升反馈环：迁移率↓→延迟↑→升压保频→功耗↑→更热；漏电↑→静态功耗↑→更热
- 热耦合矩阵 + 电路活动图共同输入仿真：某器件 1W 在多久后给邻居多少温升；孤立器件表征进真实密度会低估

## 可实现模块（eda-platform 扩展接口建议）

```python
# physics/reliability.py 建议接口（供 eda-physics 实现时参考）
@dataclass
class StressCondition:
    vgs: float
    vds: float
    temp_k: float
    area_um2: float
    freq_hz: float

class TDDBModel:
    """Percolation + E/T 加速：t_bd = A*exp(Ea/kT)*exp(-gamma*E) 再套 Weibull(beta, eta)。
    约束：外推前先验证多档应力下 Weibull beta 一致（机制未切换）。"""

    def lifetime(self, stress: StressCondition, pct: float = 63.2) -> float: ...

class HCIModel:
    """损伤比例于 I_sub 峰值（衬底电流，不是 I_ds）；age = integral (I_sub/I_ds)^m dt。"""

    def vth_shift(self, stress_history: list[StressCondition]) -> float: ...

class SelfHeatingModel:
    """频率相关等效热阻网络 R_th(f, pulse_width)；输出局部 ΔT 供 HCI/BTI/TDDB 作温度输入（耦合）。"""

    def local_temp_rise(self, power: float, pulse) -> float: ...
```

## 实现状态（2026-08-28 已落地 ✅）

接口建议已实现在 `eda-platform/backend/src/eda_platform/physics/reliability.py`（360 行）：
`TDDBModel`（渗流寿命核 + E/T 加速 + Weibull 面积缩放）、`StressCondition`、`PulseSpec`、
`HCIModel`（I_sub 损伤 + age 积分 + 偏置扫描）、`SelfHeatingModel`（Foster 级联瞬态热阻 +
热耦合矩阵）、`weibull_beta_mle`（含右截尾）、`weibull_sf`、`beta_consistent_across_stress`、
`demo_coupled_aging`（SHE→TDDB 耦合：实测 12.5K 温升 → 2.53x 加速）。已从
`physics/__init__.py` 导出。测试 `tests/test_reliability.py`——三模块合计 62 条新增，
`PYTHONPATH=src pytest tests/` 全量 **254 passed**（2026-08-28）。运行环境：host Python
受 PEP 668 管控，先 `python3 -m venv --system-site-packages backend/.venv` 再装 pytest/ruff
（numpy/scipy 走 system-site）。

**实现教训（写测试前先数值验证物理）**：初版 8 个测试失败多数是"测试设计物理错"而非代码
bug——demo 场景热数值不真实（2mW×200K/W 仅 0.4K 温升，撑不起耦合故事，改真实单管热阻
量级后 ΔT=12.5K）、截尾 MLE"截尾必改善估计"不成立（只在信息性截矢下向上修正）。先在
一次性脚本里跑数值、确认物理方向，再落断言。

## 验收测试（已逐条验证 ✅ 2026-08-28）

- [x] 面积缩放：lg(t50)~lg(A) 线性，斜率量级检查
- [x] 多档应力 Weibull beta 一致性（机制未切换证据）
- [x] SHE 瞬态峰值 > 稳态值
- [x] HCI 最严苛点 ≠ 电流最大点

## 来源锚点

- 《TDDB：绝缘层为什么会被电场一点点击穿》2026-08-25
- 《热载流子效应：高能载流子如何损伤界面》2026-08-26
- 《自热效应：局部温升怎样改变性能》2026-08-27
- 公众号「蒙卡乔叔」(MtCr_Josh)；全文 JSON 存 `workspace/mtcr-research/mtcr_articles.json`（调研于 2026-08-28）

## Related Skills

- **eda-platform-development** — 平台实现落点（physics/ 层）
- **memory-device-modeling** — 存储器器件侧（保持时间/刷新同样受温度与老化影响）
