---
name: parasitic-extraction-methods
description: 做寄生提取或互连建模时用：RC/RLC 精度分层、耦合电容处理、SPEF 输出与闭环签核。
version: 1.1.0
author: orchestrator (fusion from 蒙卡乔叔/MtCr_Josh WeChat series)
license: internal
metadata:
  hermes:
    tags: [eda, parasitic, rc-extraction, crosstalk, spef, interconnect]
    related_skills: [eda-platform-development, semiconductor-reliability-physics]
---

# 寄生参数提取方法（Parasitic Extraction Methods）

> 来源：微信公众号「蒙卡乔叔」(MtCr_Josh) 2026-08-14《寄生参数提取：版图上的线如何变成电路的一部分》深度提炼。
> 定位：为 eda-toolchain 提供寄生提取的精度分层判据与工具链对接知识；与 eda-platform 现有 `physics/frw.py`（FRW 随机行走电容提取）互补。

## When to Use

- 为 EDA platform 扩展寄生提取模块（规则表/模式匹配 RC、耦合网络）
- 判断互连建模精度档位（lumped π/T → 分布多段 → RLC/传输线 → 全波电磁）
- 处理耦合电容的保留/折算决策与 SPEF/DSPF 输出
- 向设计侧解释「原理图正常、版图后变差」的来源

## 核心图像：几何世界→电学世界的翻译层

原理图只表达"谁连接谁"；版图后每条金属线都有宽度/厚度/长度/层间距/邻近关系，
由材料和几何共同决定寄生 R/C（纳米尺度下表面与界面散射抬高有效电阻率）。
寄生提取真正改变的是验证方式：**让版图物理影响进入电路分析闭环**（签核提取不可被布线前估算替代）。

## 精度分层判据（文章提炼）

| 档位 | 模型 | 适用场景 |
|------|------|---------|
| L1 | 集总（单 R+单 C，或 π 型/T 型） | 短线/低速；π 型=中间串联 R 两端分 C，T 型=两段串联阻抗夹并联支路；选型看端口条件/频率/精度，无绝对优劣 |
| L2 | 分布多段 RC | 数字后端时序与 SI 分析主体；长线/快边沿必须分段（何时分段综合工艺/负载/回流路径/误差要求，不凭固定长度）|
| L3 | RLC | 高速时钟/高速接口/电源网络/模拟射频互连（取决于边沿、电气长度、回流路径、分析目标）|
| L4 | 全波电磁 | 以上都不够时的最终手段 |

- 电流密度↑ 不简单等于电阻↑，还会加重压降/焦耳热/可靠性压力，并经自热间接改变电阻（与 reliability skill 联动）

## 耦合电容处理（串扰来源）

- 对地电容：翻转充放电 → 增加延迟；耦合电容：不只加负载，还把攻击线(aggressor)变化转移到受害线(victim) → 串扰
- 串扰大小由耦合电容+线间距+平行长度+驱动强弱+受害线状态+翻转时序共同决定
- 提取不能只记录对地电容，**重要网络的耦合关系必须显式保留**
- 弱耦合简化：按阈值/比例/网络重要性折算进等效对地电容或忽略；阈值无统一答案，由芯片类型/分析目标/误差预算/签核规则共同决定

## 提取流程与数据结构（工具链对接）

1. 读版图数据 + 工艺提取技术文件（ITF 类：描述不同材料/线宽/间距/厚度/层叠下的寄生行为，数据来自场求解+测试结构+工艺标定——不是脱离物理模型的简单外推）
2. 识别 net/线段/通孔及空间关系
3. 规则表或模式匹配：查目标走线与上下层、左右邻线几何关系 → 插值得 R/C
4. 组合成带内部节点和耦合关系的 RC 网络 → 输出 SPEF/DSPF 给 STA、串扰分析、SPICE
5. 通孔电阻：单独保留（便于观察局部影响）或网络约简时合并（缩小规模）；按工具能力/输出格式/精度要求选择

## 分布效应与模型选择

- 整线压缩成单 R+单 C 会丢分布效应；长/快互连各处电压电流不同时刻不同方式变化
- 分段判据：互连更长、边沿更快、或单段模型误差超目标 → 拆多段 → 传输线/电磁模型

## 可实现模块（eda-platform 扩展接口建议）

```python
# signal/parasitic.py 建议接口（与现有 physics/frw.py 场求解互补）
class PiModel:
    """集总 π 型：mid R + 两端 C/2。验收：短线延迟误差 < 5%（对照分布 RC）。"""
    ...

class CoupledRCNetwork:
    """带耦合电容的 RC 网络：nodes + cap_matrix（off-diag = 耦合项）。
    输出 SPEF 格式（*D_NET 段含 coupling cap）。"""
    def to_spef(self) -> str: ...

class RuleTableExtractor:
    """从 ITF 风格查找表按线宽/间距/厚度插值 R/C（模式匹配的简化实现）。"""
    def lookup(self, width, spacing, layer) -> tuple: ...

def crosstalk_peak(coupling_c: float, aggressor_slew: float, victim_drive: float) -> float:
    """串扰峰值一阶估算（比值缩放），供快速筛选哪些 net 对需要显式耦合提取。"""
    ...
```

## 实现状态（2026-08-28 已落地 ✅）

接口建议已实现在 `eda-platform/backend/src/eda_platform/signal/parasitic.py`（364 行），
已从 `signal/__init__.py` 导出。实际 API 与建议略有出入，以实现为准：
`WireSegment`（dataclass：length_um/width_um/thickness_um/dielectric_eps_r/rho_uohm_cm，
内部自算 r_total/c_total）、`PiModel(seg)`/`TModel(seg)` 的 `.delays(c_load)` 返回
`t_pi_s`/`t_t_s`/`t_lumped_s` 键 + `lumped_vs_distributed_error()`、`CoupledRCNetwork`
（resistor/ground_cap/coupling_cap 增量构建、全电容矩阵 Elmore、`to_spef()`）、
`RuleTableExtractor().lookup(w, s, layer)` → `(R_ohm_per_um, C_gnd_F_per_m,
C_coup_F_per_m)`（耦合项公式 `ε₀·4·w/s`，**勿漏宽度因子**）、`crosstalk_peak(cc, rs,
cl, vswing)`。与既有 `physics/frw.py` 场求解互补。测试 `tests/test_parasitic.py`；
三模块合计 62 条新增，全量 **254 passed**（2026-08-28）。

**π/T 集总误差的实现教训**：零负载下 π 与 T 延迟本就相差 ~20%（两拓扑从两侧夹住分布 RC
真值 0.38·RC）——"<5%" 验收只在 **C_load ≫ C_wire**（真实负载场景）时成立。写对照测试
前先确认物理前提，别把拓扑固有差异当 bug 修。耦合折算进对地电容后 Elmore 延迟近似不变
（对角占优），真实差异体现在 quiet-victim 串扰——断言应打在串扰上。

## 验收测试（已逐条验证 ✅ 2026-08-28）

- [x] π/T 模型对照分布式 RC：短线（< λ/10）+ 真实负载下延迟误差 < 5%
- [x] 耦合保留 vs 折算：串扰峰值差异可见（保留版安静受害者有串扰，折算版趋零）
- [x] SPEF 输出可被简单解析器读回（D_NET/CONN/CAP/RES 段完整）
- [x] 规则表插值物理合理（平板+边缘因子，对照 FRW 量级）

## 来源锚点

- 《寄生参数提取：版图上的线如何变成电路的一部分》2026-08-14，公众号「蒙卡乔叔」(MtCr_Josh)
- 全文 JSON 存 `workspace/mtcr-research/mtcr_articles.json`（调研于 2026-08-28）
- 平台现有实现：`eda-platform/backend/src/eda_platform/physics/frw.py`（FRW 随机行走电容）

## Related Skills

- **eda-platform-development** — 平台实现落点（signal/ 层 + physics/frw.py 场求解）
- **semiconductor-reliability-physics** — 自热与电迁移使寄生随老化漂移（提取不是一次性的）
