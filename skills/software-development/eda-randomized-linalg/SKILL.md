---
name: eda-randomized-linalg
description: >-
  Randomized Numerical Linear Algebra for EDA — dashSVD 动态移位随机 SVD、
  固定精度低秩近似、随机 Cholesky、随机 GMRES、随机 PCA、张量分解。
  基于喻文健方法体系（ACM TOMS'24 Algorithm 1043 + SIAM J. Matrix Anal.'18 +
  TCAD'24 + ICCAD'23 + IJCAI'23）。Use when implementing scalable solvers
  for large sparse matrices in circuit/power-grid/parasitic extraction.
version: 1.0.0
platforms: [macos, linux]
metadata:
  hermes:
    tags: [eda, randomized-nla, svd, cholesky, gmres, pca, tensor, sparse]
    related_skills:
      - eda-frw-capacitance
      - eda-bem-field-solver
      - eda-power-grid-analysis
      - eda-platform-development
---

# 随机化数值线性代数（Randomized NLA for EDA）

大规模稀疏/稠密矩阵的高效数值算法。方法体系来自喻文健 Numbda 课题组，
覆盖从 SVD/PCA 到 Cholesky/GMRES 预条件到张量分解的全谱系。

## 何时使用

- 大规模稀疏矩阵截断 SVD（电路仿真/网络嵌入）
- 低秩矩阵近似（模型降阶、数据压缩）
- 预条件子构造（电源网格仿真、电路仿真）
- 自适应秩 PCA（大数据分析）
- 张量列车分解（多维度数据）

## 核心原理

### 1. dashSVD 动态移位随机 SVD（J04, ACM TOMS'24, Algorithm 1043）
- 随机 SVD 基础：
  ```
  Y = A·Ω            # Ω: 标准正态随机矩阵 (n×k+p)
  Q = orth(Y)        # QR 分解得到列正交基
  B = Q^T·A          # 投影到低维
  [U,S,V] = svd(B)   # 小矩阵精确 SVD
  U ≈ Q·U            # 还原
  ```
- **动态移位幂迭代**改进精度：
  ```
  第 i 次迭代：Y ← A·(A^T·Y) + σ_i·Y   # σ_i 动态更新
  σ_i = 前次迭代奇异值估计（动态移位）
  ```
- **精度控制机制**：逐向量误差界近似监控，满足精度立即停止
- 误差界证明：移位幂迭代的近似误差上界

### 2. 固定精度低秩近似（J19, SIAM J. Matrix Anal.'18）
- QB 分解框架：`A ≈ Q·B`，Q 正交、B 小矩阵
- 固定精度问题：给定容差 ε，自动确定秩 k（而非固定 k）
- pass 数 vs 精度权衡：基础算法 1 pass，幂迭代 2-3 pass 提精度
- 自适应算法：块采样 + 误差估计循环

### 3. 随机 Cholesky 预条件（J02 RCholT, TCAD'24 / C49 PowerRChol, ASPDAC'24）
- 用于对称对角占优 M-矩阵（SDDM）——电源网格典型
- RChol：随机采样列 + Cholesky 更新，构造稀疏预条件
- **RCholT 阈值多采样**：用户定义阈值控制预条件子稀疏度，
  可包含更多 fill-in → 更有效预条件
- 实测：RCholT 比 RChol 快 1.7×，比图稀疏化快 2.3×（PG benchmark）

### 4. 随机 GMRES（C47, ICCAD'23）
- 随机 Arnoldi：用草图最小二乘（sketched LS）正交化 Krylov 基
- 降低 Arnoldi 过程成本（每次迭代的 O(n·k) 正交化开销）
- 应用于电路仿真线性系统

### 5. 自适应随机 PCA（C53, IJCAI'23）/ 单遍 PCA（C62, IJCAI'17）
- 容差驱动自动确定秩
- 单遍：数据流一次扫描完成 PCA（大数据不可加载内存时）
- 加速随机矩阵：SRFT（子采样随机 Fourier 变换）/ SRHT（Hadamard）/ 稀疏符号

### 6. 张量列车分解（J11, JCAM'22）
- TT-SVD：逐维 SVD 折叠，稀疏数据利用稀疏结构加速
- 张量补全 TV 正则（J16）：总变差正则化 TT
- 张量网络随机 SVD（J20）：大矩阵低秩近似的张量化

## 标准实现步骤

```python
# dashSVD 核心
def dash_svd(A, k, p=10, tol=1e-6, max_power=5):
    """动态移位随机 SVD。A: (m,n) sparse, k: 目标秩"""
    m, n = A.shape
    Omega = np.random.randn(n, k+p)
    Y = A @ Omega
    Q, _ = np.linalg.qr(Y)
    sigma = None
    for _ in range(max_power):
        Y2 = A.T @ (A @ Q)
        if sigma is not None:
            Y2 = Y2 + sigma * Q          # 动态移位
        Q, _ = np.linalg.qr(Y2)
        # 估计当前奇异值（廉价近似）更新 sigma
        B = Q.T @ A
        _, s, _ = np.linalg.svd(B, compute_uv=False)
        sigma = s[0] if len(s) else 0.0
        # 精度监控：||A - Q Q^T A|| 估计 < tol 则停
    B = Q.T @ A
    Ub, s, Vh = np.linalg.svd(B, full_matrices=False)
    U = Q @ Ub
    return U[:, :k], s[:k], Vh[:k, :]

# 固定精度自适应（J19）
def fixed_precision_qb(A, eps, block=8):
    """自动确定秩 k 使 ||A - QB|| <= eps||A||"""
    Q = np.empty((A.shape[0], 0))
    Omega = np.random.randn(A.shape[1], block)
    while True:
        Y = A @ Omega
        Y -= Q @ (Q.T @ Y)               # 正交化
        q, _ = np.linalg.qr(Y)
        Q = np.hstack([Q, q])
        # 误差估计
        B = Q.T @ A
        err = np.linalg.norm(A - Q @ B, 'fro') / np.linalg.norm(A, 'fro')
        if err <= eps:
            return Q, B
        Omega = np.random.randn(A.shape[1], block)

# RCholT 预条件（J02）
def rchol_t_preconditioner(A, threshold=0.1):
    """阈值多采样随机 Cholesky 预条件。A: SDDM 矩阵"""
    # 1. 采样列：按列对角权重概率采样
    # 2. 稀疏 Cholesky 更新：超过阈值的 fill-in 保留
    # 3. 返回 M ≈ A^{-1} 的 LinearOperator
    ...
```

## 验证命令

```bash
# dashSVD 精度验证
python -c "
import numpy as np
from scipy import sparse
# 构造低秩+噪声矩阵
m, n, k_true = 2000, 1000, 20
rng = np.random.default_rng(42)
U = rng.standard_normal((m, k_true)); V = rng.standard_normal((n, k_true))
A = U @ V.T + 0.01*rng.standard_normal((m, n))
# 运行 dash_svd(A, 20)，对比 np.linalg.svd 前 20 个奇异值
# 相对误差 ||s_dash - s_exact||/||s_exact|| < 1e-2 为通过"

# RCholT 收敛验证：PCG 迭代次数应远小于无预条件
# 固定精度验证：返回秩 k 使得实际误差 <= eps
```

## 常见陷阱

1. **oversampling p**：p 太小时基不完整（建议 p ≥ 5 或 k/2）
2. **幂迭代 pass 数**：2-3 pass 足够，更多收益递减
3. **移位 σ 更新**：动态移位必须用当前奇异值估计，固定移位效果差
4. **稀疏矩阵**：A@Omega 用稀疏-稠密乘法，不要先 densify
5. **RCholT 阈值**：threshold 太小 → 预条件子太密；太大 → 太稀疏无效
6. **误差估计**：||A-QB|| 估计必须用随机估计器（Hutchinson），不要直接
   计算全矩阵范数（O(n²) 内存）
7. **seed 固定**：随机算法必须固定 seed 才能可复现

## 参考论文（全部在本地语料库）

- J04 dashSVD (ACM TOMS'24, Algorithm 1043)
- J19 固定精度低秩 (SIAM J. Matrix Anal.'18)
- J03 svds-C (SoftwareX'24)
- J02 RCholT (TCAD'24) / C49 PowerRChol (ASPDAC'24)
- C47 随机 GMRES (ICCAD'23)
- C53 自适应 PCA (IJCAI'23) / C62 单遍 PCA (IJCAI'17)
- C56 pass-efficient SVD (ICCS'18)
- J11 张量列车 (JCAM'22) / J16 TV 张量补全 / J20 张量网络 SVD
- J06 SketchNE (TKDE'23) — 图稀疏化+分解应用
- C55 有效电阻 (DATE'23) — Cholesky 近似逆

## 与其他 skill 的关系

- `eda-power-grid-analysis`：随机 Cholesky/GMRES 是其核心求解器
- `eda-frw-capacitance` / `eda-bem-field-solver`：预条件与宏模型求解
- `eda-platform-development`：eda-platform 代码库 linalg.py 扩展方向
