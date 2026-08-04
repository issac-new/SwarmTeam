---
name: eda-hypergraph-routing
description: >-
  Hypergraph Partitioning 与 Ordered Escape Routing — BlasPart 确定性并行划分、
  EasyPart FPGA 仿真划分、HGNN-Part 生成模型划分、MCMCF/MCMC-Escape 逃逸布线。
  基于喻文健方法体系（ICCAD'24/25 + DAC'23 + DATE'26 + TODAES'26）。
  Use when implementing hypergraph partitioners for FPGA emulation/VLSI
  partitioning or escape routing algorithms for PCB/pin-array design.
version: 1.0.0
platforms: [macos, linux]
metadata:
  hermes:
    tags: [eda, hypergraph, partitioning, fpga, escape-routing, mcts, pcb]
    related_skills:
      - eda-platform-development
      - eda-ai-parasitic-ml
---

# 超图划分与逃逸布线（Hypergraph Partitioning & Escape Routing）

大规模超图划分算法与有序逃逸布线算法。方法体系来自喻文健 Numbda 课题组，
覆盖 FPGA 硬件仿真（多 FPGA 系统）与 PCB 引脚阵列布线的核心算法。

## 何时使用

- FPGA 多板硬件仿真系统的网表划分（MFS 分区）
- VLSI 设计/HPC/存储分片等平衡超图划分
- PCB 引脚阵列有序逃逸布线（OER）
- 需要确定性（可复现）划分结果的场景

## 核心原理

### 1. BlasPart 确定性并行划分（C45, ICCAD'24）
- **问题**：平衡超图划分（NP-hard），并行划分通常非确定
- **框架**：递归多级二分（recursive multilevel bisection）
  - 粗化（coarsening）→ 初始划分 → 细化（uncoarsening + refinement）
- **确定性**：级别相关 FM（Fiduccia-Mattheyses）细化 + 确定性 tie-breaking
  - 相同的输入 → 相同输出（VLSI 设计必需：可复现回归）
- **平衡性**：分区数增加时平衡是关键（level-dependent 平衡处理）

### 2. EasyPart FPGA 仿真划分（C48, DAC'23）
- 多 FPGA 系统（MFS）网表→超图，超边=网络
- 综合处理：容量约束（每个 FPGA 的 LUT/FF/BRAM 容量）、
  时间复用（TDM）开销、FPGA 间连接约束
- 与 HyperSilicon 合作（工业验证）

### 3. HGNN-Part 生成模型划分（date262, DATE'26）
- 深度学习方法用于划分的痛点：GNN 把超图转普通图 → 丢失高阶关系
- HGNN-Part：直接处理超图结构（超边高阶性保留）
- 超图生成模型：学习超图分布 → 生成辅助超图改进划分质量

### 4. MCMCF-Router 多容量有序逃逸布线（J01, TODAES'26）
- OER：信号引脚按给定顺序布线到引脚阵列边界
- **多容量**：相邻引脚间布线容量 > 1（实际 PCB 更真实）
- 网格/交错（staggered）引脚阵列统一处理

### 5. MCMC-Escape MCTS 逃逸布线（todaes262, TODAES'26）
- 蒙特卡洛树搜索（MCTS）驱动的 OER
- 初始求解 → 改进 MCTS（布线路径搜索 + 容量分配）→ 线重路由收尾
- 比 RL 方法更可控（容量建模显式）

## 标准实现步骤

```python
# BlasPart 核心流程（C45）
def blaspart_partition(hypergraph, k, balance=0.05, seed=42):
    """确定性并行超图划分"""
    # 1. 粗化：超边收缩（确定性选择，seed 驱动但结果确定）
    # 2. 初始划分：贪心图增长（GGGP）确定性变体
    # 3. 细化：级别相关 FM（cell gain 计算 + 确定性 tie-break）
    #    - gain = 移动后切边数减少量
    #    - 只允许不破坏平衡约束的移动
    # 4. 递归：k 路 → log2(k) 层二分
    return partition  # 确定性：同输入同输出

# EasyPart FPGA 划分（C48）
def easypart_fpga(netlist_hypergraph, fpga_capacities, tdm_factor):
    """多 FPGA 硬件仿真划分"""
    # 1. 超图构建：net → hyperedge
    # 2. 容量感知多级划分：FPGA 资源容量约束
    # 3. TDM 感知：跨 FPGA 网络的时间复用开销优化
    # 4. 迭代细化：平衡 + 最小割 + TDM 加权
    ...

# MCMCF-Router 逃逸布线（J01）
def mcmcf_escape(pins, capacities, order):
    """多容量有序逃逸布线"""
    # 1. 构建容量图：引脚间隙容量（边容量）
    # 2. 按顺序逐一布线：每引脚 → 边界的最短路径（容量约束）
    # 3. 冲突处理：容量满 → 绕行/调整
    ...
```

## 验证命令

```bash
# BlasPart 验证协议
# 1. 平衡性：max_part_size / avg_part_size <= 1 + balance
# 2. 切边数（cutsize）：与 hMETIS/PaToH 对比
# 3. 确定性：同输入跑 2 次，输出 partition 完全一致
python -c "
import numpy as np
# 简单超图：3 超边，6 节点，2 分区
# 验证：所有分区大小差 <= 1，切边数 = 期望值"

# MCMCF 验证：给定 pin 阵列 + 顺序，布线成功率 100%，
# 无容量违例（相邻引脚间走线数 <= 容量）
```

## 常见陷阱

1. **确定性 ≠ 种子固定**：确定性要求 tie-breaking 规则与并行归约顺序无关
2. **平衡约束**：FM 移动必须实时检查平衡，否则后期无法恢复
3. **超边权重**：FPGA 仿真中 TDM 代价必须进权重（切边数 ≠ 真实代价）
4. **MCTS 探索**：逃逸布线 MCTS 需要访问次数初始化（避免零访问死区）
5. **容量建模**：多容量必须显式建模，单容量假设会导致布线失败
6. **递归二分**：k 非 2 幂时最后层处理要小心（虚拟分区技巧）

## 参考论文（全部在本地语料库）

- C45 BlasPart (ICCAD'24)
- C48 EasyPart (DAC'23)
- date262 HGNN-Part (DATE'26)
- J01 MCMCF-Router (TODAES'26)
- todaes262 MCMC-Escape (TODAES'26)
- aspdac262 多 FPGA TDM 分配 (ASP-DAC'26)
- aspdac263 参数调优 (ASP-DAC'26)

## 与其他 skill 的关系

- `eda-platform-development`：eda-platform ipcore/ 模块扩展方向（FPGA
  仿真基础设施）
- `eda-ai-parasitic-ml`：HGNN-Part 的图学习基础设施可复用
- `eda-power-grid-analysis`：无直接依赖，但同一物理设计流程
