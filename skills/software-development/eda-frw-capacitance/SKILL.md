---
name: eda-frw-capacitance
description: >-
  Floating Random Walk (FRW) 3-D capacitance extraction — 基于喻文健教授
  RWCap/专著方法体系（Springer 2023 + TCAD'13/24/20/17）。Use when implementing
  capacitance extraction solvers for VLSI interconnects, TSV/3D-IC structures,
  or any electrostatic field solver needing mesh-free Monte Carlo methods.
version: 1.0.0
platforms: [macos, linux]
metadata:
  hermes:
    tags: [eda, frw, capacitance, monte-carlo, parasitic-extraction, field-solver]
    related_skills:
      - eda-bem-field-solver
      - eda-randomized-linalg
      - eda-platform-development
---

# FRW 电容提取（Floating Random Walk Capacitance Extraction）

实现 VLSI 互连 3-D 寄生电容提取的浮动随机行走求解器。方法体系来自喻文健
Numbda 课题组（清华）：专著《Monte Carlo Methods for PDEs with Applications
to EDA》(Springer 2023) 第 2/4/5/6/7/8/9/10/11 章 + 系列论文。

## 何时使用

- 实现互连/TSV/3D-IC 电容提取求解器（field solver 级别）
- 需要无网格、可并行、天然支持多介质的静电求解
- 全芯片级电容提取（BEM/FEM 内存瓶颈时的替代）
- 电容宏模型 / 敏感结构加密（macromodel-aware）

## 核心原理（来自专著 §2 + J30）

### 1. 概率势论基础
- 拉普拉斯方程解 = 边界上势的期望：`φ(r) = E[φ(r_k)]`，r_k 为首次击中
  导体边界的行走终点（Walk-on-Spheres 思想）
- 浮动随机行走：从主导体 j 的高斯面 Gj 出发，每次在最大无导体立方体
  （transition cube）表面按离散概率采样下一点，直到击中某导体 i
- 电容公式（Gauss 定理）：
  ```
  Qj = ∫∫ F(r)·ω(r,r')·P(r,r')·φ(r') dr' dr
  ω(r,r') = -∇P(r,r')·n̂(r) / (g·P(r,r'))   # weight value
  g: ∫Gj F(r)g dr = 1 的归一化常数
  ```
- 平均权重值即为电容：`Cji = (1/N) Σ ω_n`

### 2. 多介质处理（关键难点）
- **球面过渡域**（基本版）：介电界面处用半球 Green 函数，简单但跳数多
- **数值表征 cross-interface 转移概率**（RWCap 核心，160× 加速）：
  预计算单位立方体的表面 Green 函数 P 和权重 W，离散化存储
- **八分过渡立方体**（J15, TCAD'20）：共形介电，利用八分对称性——
  转移概率与单介电立方体紧密关联（理论证明），on-the-fly 采样
- **MicroWalk**（TCAD'26）：随机有限差分 FRW 转移，任意介电，802× 加速于
  FDM 精确解，可证明无偏

### 3. 方差缩减（决定收敛速度）
- **重要性采样**：Gaussian 面上按电荷密度加权采样起点
- **分层采样**：Gaussian 面分区，每区采样，降低样本相关性
- **对称多重射击 SMS**（J05, TCAD'24）：一条行走同时从对称点发射，
  理论证明方差减少
- **Macromodel-aware**（J17, TCAD'20）：敏感结构用修正 FDM 生成可靠
  宏模型（BEM 宏模型违反宏模型性质误差大），FRW 遇宏模型直接跳转

### 4. 空间管理（全芯片级性能）
- **八叉树（octree）**：存储所有导体包围盒，支配关系剪枝
- 行走每跳需查询最近导体距离 → 八叉树查询 O(log n)
- 并行构建八叉树（J30 §4.4）

### 5. GPU 友好（C65, DATE'13）
- 逆累积概率数组跳跃（避免逐点采样循环）
- 独占显存 + 额外起点（避免 bank conflict）
- 多网络并发提取

### 6. 分布式并行 + 可复现（专著 §11 + DATE'25 FRW-RR）
- 分布式随机行走：每进程独立 PRNG，最后归约
- 数值可复现：barrier 同步方案 或 精度标准分配方案
- FRW-RR：固定 PRNG seed、DOP-independent（与线程数无关）

## 标准实现步骤

```python
# 1. 几何预处理
#    - 导体列表 (boxes)，包围盒
#    - 构建八叉树（支配关系剪枝）
#    - 构建主导体高斯面（矩形面片集合）

# 2. 预表征（多介质时）
#    - 数值求解单位立方体表面 Green 函数 P(r, r')
#    - 存储转移概率表 + 权重表（离散化网格）

# 3. FRW 主循环
#    for walk in range(N_walks):
#        r = sample_on_gaussian_surface(master)
#        while not on_conductor(r):
#            cube = max_conductor_free_cube(r)   # 八叉树查询
#            r_new = sample_on_cube_surface(cube, P_table)  # 逆累积采样
#            weight *= omega(r, r_new)  # 介电界面处用球域/八分立方体
#            r = r_new
#        C[hit_conductor] += weight
#    C /= N_walks

# 4. 方差缩减
#    - Gaussian 面重要性采样 + 分层采样
#    - SMS 对称多重射击（可选）

# 5. 验证
#    - 解析解对比（平行板电容 C = εA/d）
#    - 与 BEM/FDM 参考解对比（误差 < 1%）
#    - 收敛性：C(N) vs 1/sqrt(N) 理论收敛
#    - 可复现性：同 seed 两次运行结果一致
```

## 验证命令

```bash
# 平行板解析解验证：C = ε0·εr·A/d
# 例：10x10um 板，间距 1um，εr=3.9 → C ≈ 3.45 fF
python -c "
import numpy as np
eps0 = 8.854e-12; er = 3.9
A = 10e-6*10e-6; d = 1e-6
print(f'analytic: {eps0*er*A/d*1e15:.3f} fF')"

# 收敛性检查：N=1000/10000/100000，std 应随 sqrt(N) 下降
# 可复现性：固定 np.random.seed(42)，两次结果 bitwise 一致
```

## 常见陷阱

1. **转移概率必须归一化**：Σ P(r,r') = 1，否则结果偏差
2. **立方体必须"最大无导体"**：否则击中概率计算错误
3. **多介质界面处不能用单介电立方体**：必须球域/八分立方体/数值表征
4. **权重值计算方向**：ω 用 ∇P·n̂，法向方向不能反
5. **Gaussian 面必须在导体外、且不与相邻导体重叠**
6. **方差不减 = 白跑**：先做重要性采样再做分层采样
7. **seed 固定**：否则 CI 回归无法复现（FRW-RR 教训）

## 参考论文（全部在本地语料库）

- 专著《Monte Carlo Methods for PDEs with Applications to EDA》Springer 2023（12 章全）
- J30 RWCap (TCAD'13) — 基础求解器
- J05 SMS (TCAD'24) — 对称多重射击
- J15 八分立方体 (TCAD'20) — 共形介电
- J23 非曼哈顿 (TCAD'17) — 一般形状
- J25 圆柱 TSV (TCAD'15)
- J17 宏模型 (TCAD'20) / C63 (DATE'16 Best Paper)
- C50 解析 Green 函数 / C65 GPU (DATE'13)
- tcad26_1 MicroWalk (TCAD'26)
- date25 FRW-RR (DATE'25)
- aaai26 DeepRWCap (AAAI'26) — 神经引导

## 与其他 skill 的关系

- `eda-bem-field-solver`：BEM 是确定性场求解器（小规模高精度），FRW 是
  蒙特卡洛（大规模可并行）——两者互为验证基准
- `eda-randomized-linalg`：FRW 的 GMRES 预条件、宏模型 FDM 求解可用其方法
- `eda-platform-development`：eda-platform 代码库结构
