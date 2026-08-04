---
name: eda-bem-field-solver
description: >-
  Boundary Element Method (BEM) 场求解器 — 3-D 电容/电阻/电感/衬底寄生参数提取。
  基于喻文健 HBBEM/QMM-BEM/混合BEM 方法体系（TMTT'03/04 + TCAD'06/08 + EABE'07）。
  Use when implementing deterministic field solvers for parasitic extraction,
  substrate coupling, or frequency-dependent impedance.
version: 1.0.0
platforms: [macos, linux]
metadata:
  hermes:
    tags: [eda, bem, boundary-element, capacitance, inductance, substrate, field-solver]
    related_skills:
      - eda-frw-capacitance
      - eda-randomized-linalg
      - eda-platform-development
---

# BEM 场求解器（Boundary Element Method Field Solvers）

实现 3-D 寄生参数提取的确定性边界元场求解器。方法体系来自喻文健 Numbda
课题组：HBBEM（层次块 BEM）、QMM-BEM（准多介质加速）、混合 BEM、直接 BEM。

## 何时使用

- 小规模高精度结构提取（FRW 的验证基准）
- 衬底耦合寄生提取（任意掺杂轮廓）
- 频变电感/阻抗提取
- 需要输出完整电容矩阵（而非逐对电容）

## 核心原理

### 1. BEM 基础（拉普拉斯方程边界积分）
- 3-D 拉普拉斯方程 → 边界积分方程（BIE）：
  ```
  φ(p) = ∫S G(p,q)·σ(q) dq        # 单层势表示
  G(p,q) = 1/(4π|p-q|)            # 自由空间 Green 函数
  ```
- 离散化：导体/介电界面网格化，未知量 σ（电荷密度）或 φ（势）
- 组装稠密矩阵 → 求解线性系统（C·σ = V）
- 电容矩阵：C_ij = Q_i/V_j（各导体分别置单位电压求解）

### 2. HBBEM 层次块方法（J43, TMTT'04）
- 3-D 结构层次分区为 BEM 块，全局计算化为块内局部计算
- 直接输出全局电容矩阵（无需逐对提取）
- 加速技术：层次八叉树 + 远处块低秩近似

### 3. QMM 准多介质加速（J44, TMTT'03）
- 实际 3-D VLSI 结构介质分层 → 每层"准多介质"处理
- 虚拟介质切割：多介质结构分割为单介质子问题
- 相邻层耦合用多层 Green 函数/数值技术处理
- 快于全 BEM 一个量级，精度损失 < 2%

### 4. 直接 BEM 衬底提取（J36/J39, TCAD'06/08）
- **任意掺杂轮廓**：直接 BEM 离散掺杂分布，无需 Green 函数近似
- **多频加速**（Sherman-Morrison-Woodbury）：
  ```
  先解频率无关实线性系统一次（A·x = b）
  频变参数 = S-M-W 公式从 A^{-1} 更新：
  (A + UV^T)^{-1} = A^{-1} - A^{-1}U(I + V^T A^{-1}U)^{-1}V^T A^{-1}
  ```
  任意频率点只做 O(n²) 更新而非 O(n³) 重解

### 5. 混合 BEM 频变电感（J38, EABE'07 / C70, ISQED'06）
- 混合表面积分公式（电场 + 磁场）联合求解
- 频变电感 L(ω) = Im(Z(ω))/ω，含趋肤效应/邻近效应
- 多频点用复频率参数化 + 插值

### 6. 多层 Green 函数（J40, TMTT'06）
- 有损衬底：分层介质 Green 函数（离散复镜像法 DIM）
- 电容 + 衬底耦合统一处理

## 标准实现步骤

```python
# 1. 几何网格化
#    - 导体表面三角形网格（RWG 基函数）
#    - 介电界面网格（多介质时）
#    - 衬底区域网格（任意掺杂时）

# 2. 组装 BEM 矩阵
#    - 计算 Green 函数 G(p,q) 各元素
#    - 奇异积分处理（自单元：解析积分/去奇异变换）
#    - 多介质：界面连续性条件联立

# 3. 求解
#    - 小规模：直接 LU
#    - 大规模：GMRES + 预条件（参见 eda-randomized-linalg）
#    - 多右端项：块求解 / 共享分解（J30 中多导体）

# 4. 输出
#    - 电容矩阵 / 电阻矩阵 / 频变阻抗 Z(ω)
#    - Sherman-Morrison-Woodbury 多频加速

# 5. 验证
#    - 平行板解析解 C = εA/d
#    - 球-平面电容解析公式（Maxwell）
#    - 与 FRW 求解器交叉验证（误差 < 1%）
#    - 网格细化收敛性（h/2 网格误差减半 → 一阶收敛）
```

## 验证命令

```bash
# 平行板解析解
python -c "
import numpy as np
eps0 = 8.854e-12
# 1cm x 1cm 板，间距 1mm（边缘效应可忽略时）
A = 0.01*0.01; d = 0.001
print(f'C = {eps0*A/d*1e12:.4f} pF')  # ~0.885 pF"

# 网格收敛性：n=64/128/256 三角形，误差应随 h 线性下降（常数元）
# 交叉验证：同结构 FRW（1e6 walks）vs BEM，|C_frw - C_bem|/C_bem < 1%
```

## 常见陷阱

1. **奇异积分**：自单元 Green 函数奇异，必须解析处理（去奇异变换或解析公式），
   否则精度灾难性下降
2. **多介质界面**：每个均匀区域单独 BIE，界面处用电通量连续条件耦合
3. **QMM 虚拟切割**：切割面必须不切断导体
4. **S-M-W 公式**：仅当 U,V^T 低秩（少频点/少端口）时有效
5. **稠密矩阵存储**：n² 内存，n > 10k 必须用层次/快速多极加速
6. **电导 vs 电容**：衬底有损时用复介电常数 ε = ε' - jσ/ω

## 参考论文（全部在本地语料库）

- J43 HBBEM (TMTT'04)
- J44 QMM-BEM (TMTT'03) / J42 增强 QMM (TMTT'04)
- J36 直接 BEM 衬底 (TCAD'08) / J39 任意掺杂 (TCAD'06)
- J38 混合电感 (EABE'07) / C70 混合 BEM (ISQED'06)
- J40 多层 Green 函数 (TMTT'06)
- J37 多频阻抗 (MOTL'08) / C69 多频衬底 (ASPDAC'07)
- J41 浮金属填充 (TCAD'06)
- J241 QMM 方法 (CAM'03)

## 与其他 skill 的关系

- `eda-frw-capacitance`：FRW 是 MC 方法（大规模），BEM 是确定性方法
  （小规模高精度）——互为验证基准，BEM 还用于生成 FRW 宏模型（J17 提到
  BEM 宏模型误差大的教训）
- `eda-randomized-linalg`：BEM 稠密矩阵 GMRES/预条件、S-M-W 低秩更新
- `eda-platform-development`：eda-platform 代码库结构
