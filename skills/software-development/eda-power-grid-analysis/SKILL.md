---
name: eda-power-grid-analysis
description: >-
  Power Grid / Power Delivery Network (PDN) 大规模仿真 — 指数积分 R-MATEX、
  图谱稀疏化 pGRASS-Solver、随机 Cholesky 预条件、ML 驱动矩阵排序、波形压缩、
  阶跃响应眼图预测。基于喻文健方法体系（TCAD'16/23/24/21/09 + DAC'15/19 + DATE'23）。
  Use when implementing PDN transient simulation, power grid analysis, waveform
  compression, or eye diagram prediction.
version: 1.0.0
platforms: [macos, linux]
metadata:
  hermes:
    tags: [eda, power-grid, pdn, transient, sparsification, waveform, eye-diagram, signal-integrity]
    related_skills:
      - eda-randomized-linalg
      - eda-platform-development
      - eda-frw-capacitance
---

# 电源网络分析（Power Grid / PDN Analysis）

大规模电源网络（PDN）时域/频域仿真、预条件技术、波形压缩与眼图预测。
方法体系来自喻文健 Numbda 课题组（含与 UCSD Cheng 组合作成果）。

## 何时使用

- PDN 瞬态仿真（IR drop 分析、电源噪声）
- 大规模线性系统求解（百万未知量）
- 波形数据压缩（transient 仿真输出）
- 高速信号眼图预测（阶跃响应法）

## 核心原理

### 1. 指数积分 R-MATEX（J24, TCAD'16 / C64, DAC'15）
- PDN 时域方程：`C·dv/dt + G·v = i(t)`
- 矩阵指数解：`v(t+h) = v(t) + h·φ1(h·A)·b`，其中 `A = -C^{-1}G`
- **变步长能力**：矩阵分解复用，任意步长（传统固定步长才能复用分解）
- **有理 Krylov 子空间**计算 exp·v 积（核心操作）
- **DR-MATEX 分布式**：减少频繁断点导致的 Krylov 重建（叠加原理 + 缩放不变性）
- 非线性系统（C64）：指数 Rosenbrock-Euler 公式处理刚性非线性电路

### 2. 图谱稀疏化 pGRASS-Solver（J07, TCAD'23）
- 图 Laplacian 谱稀疏化：保留谱性质（有效电阻采样边）
- **并行图稀疏化算法**（实践高效）
- **域分解法（DDM）**解稀疏化后的 Laplacian 矩阵（天然并行）
- 变体：部分 Cholesky + Schur 补矩阵稀疏化
- 有效电阻计算：Cholesky 因子近似逆（C55, DATE'23 Best Paper Candidate）
- 谱临界度量：trace reduction（C57）

### 3. 随机 Cholesky 预条件（C49, ASPDAC'24 / J02, TCAD'24）
- 电源网格矩阵 = SDDM（对称对角占优 M-矩阵）
- RChol：随机采样列 Cholesky 构造稀疏预条件
- RCholT：阈值多采样，用户控制稀疏度 → 1.7× vs RChol，2.3× vs 图稀疏化
- 多右端项（瞬态多时间步）特别有效

### 4. ML 驱动矩阵排序（C61, DAC'19）
- 子域方程直接求解时，矩阵排序（AMD/METIS/ND）影响 fill-in 与效率
- SVM/ANN 分类器：基于稀疏矩阵特征（带宽、密度、图属性）自动选择最优排序
- 特征选择考虑稀疏矩阵属性；工业测试用例优于固定排序

### 5. 波形压缩（J14, TCAD'21 / C54）
- 双格式：小信号值/大信号值分别压缩
- 绝对误差 + 相对误差双保证（每个恢复值都在指定误差内）
- 分块压缩流程 + 二级无损压缩 + 三阶段流水线（simulator→viewer 快速转换）
- 异步波形支持（C54）：不同节点不同时间点

### 6. 阶跃响应眼图预测（J35, IEICE'09 / C67, ICCAD'08）
- 思路：眼图 = 所有可能 bit 序列响应的叠加（LTI 系统）
- 用阶跃响应/单位脉冲响应直接预测最坏情况眼图
- 比 SPICE 随机 bit 仿真快数量级（无需长随机序列）
- 应用于低功耗均衡器设计（J33, TCPMT'11）
- tritonic step response（C68, DAC'08）：三电平阶跃响应优化

## 标准实现步骤

```python
# R-MATEX 指数积分瞬态仿真（J24）
def r_matex_simulate(C, G, i_sources, t_end, h0):
    """PDN 瞬态仿真，变步长指数积分。C,G: sparse (n,n)"""
    # 1. 预处理：A = -C^{-1}G 的分解（一次）
    # 2. 时间循环：
    #    v(t+h) = v(t) + h·phi1(h·A)·b(t)
    #    其中 phi1(z) = (exp(z)-1)/z，b = C^{-1}i(t)
    #    有理 Krylov 计算 phi1(h·A)·b（rk = rk_phi1(A, h, b)）
    # 3. 变步长：h 按局部误差估计调整（分解复用）
    # 4. 断点（电流源切换）处：DR-MATEX 用叠加避免重建 Krylov
    ...

# pGRASS-Solver 图谱稀疏化（J07）
def spectral_sparsify(G, n_edges_target):
    """图 G=(V,E) 谱稀疏化：保留谱等价性"""
    # 1. 计算边有效电阻 R_eff（Cholesky 近似逆法，C55）
    # 2. 采样：边 (u,v) 以概率 ∝ R_eff(u,v) 保留，权重 = 1/p
    # 3. 输出稀疏图 G'（|E'| = n_edges_target << |E|）
    ...

# 波形压缩（J14）
def compress_waveform(t, v, abs_tol, rel_tol):
    """保证绝对+相对误差的波形压缩"""
    # 双格式：小值用定点/整数格式，大值用浮点格式
    # 分块压缩：每块独立误差控制
    # 二级：无损压缩（zlib/lz4）
    ...
```

## 验证命令

```bash
# R-MATEX 验证：vs 梯形积分（固定小步长参考解）
# 相对误差 < 1% 且速度更快
python -c "
import numpy as np
# 简单 RC 链 PDN 模型
n = 100; R = 1.0; C = 1e-3
# R-MATEX 解 vs scipy.solve_ivp 参考解
# 最大电压误差 < 1% 通过"

# 波形压缩验证：恢复波形每个点 |v_hat - v| <= max(abs_tol, rel_tol*|v|)
# 压缩率报告：raw_bytes / compressed_bytes
```

## 常见陷阱

1. **矩阵指数 φ1**：不要直接 expm 全矩阵（稠密爆炸），必须 Krylov 子空间
2. **变步长稳定性**：h 过大时 Krylov 需要更多维数，设上限
3. **稀疏化边权重**：采样后必须重加权（1/p），否则谱偏差
4. **RCholT 阈值**：预条件子稀疏度与质量权衡，需 benchmark 扫描
5. **波形压缩误差**：绝对+相对双保证缺一不可（纯相对误差小信号爆炸）
6. **眼图预测**：必须 LTI 假设成立（均衡器线性、信道时不变）
7. **时钟门控（J34）**：多域时钟门控导致分段线性电流源，断点处理是关键

## 参考论文（全部在本地语料库）

- J24 R-MATEX (TCAD'16) / C64 指数积分框架 (DAC'15)
- J07 pGRASS-Solver (TCAD'23)
- C49 PowerRChol (ASPDAC'24) / J02 RCholT (TCAD'24)
- C61 ML 排序 (DAC'19)
- C52 多级节点聚合降阶 / C57 trace 缩减稀疏化
- C55 有效电阻 (DATE'23)
- J34 多域时钟门控 (TCAD'09)
- J14 波形压缩 (TCAD'21) / C54 异步波形压缩
- J35 眼图预测 (IEICE'09) / C67 (ICCAD'08) / C68 tritonic (DAC'08) / J33 均衡器 (TCPMT'11)
- J28 3-D 热仿真 DDM (TCAD'13) / J27 CPU-GPU 并行热 (TVLSI'15)
- iccad251 SubtreeLU (ICCAD'25) / todaes261 并行 ILU (TODAES'26) / date261 GMRES-IR (DATE'26)

## 与其他 skill 的关系

- `eda-randomized-linalg`：随机 Cholesky/GMRES/有效电阻是其核心依赖
- `eda-platform-development`：eda-platform signal/ 模块扩展方向
- `eda-frw-capacitance`：寄生参数 → PDN 模型输入的链路
