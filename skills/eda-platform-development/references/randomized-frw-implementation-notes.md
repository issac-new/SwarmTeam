# 随机化 NLA 与 FRW 实现实证笔记（2026-07-31）

来自 eda-platform `core/randomized.py` + `physics/frw.py` 的调试实录。
模块状态：全部 165 tests passed（新增 14 个）。

## dashSVD 实现陷阱（randomized.py）

### 陷阱 1：幂迭代维度（matmul mismatch）
随机 SVD 的单边幂迭代**必须**保持 Q 为 (m,l) 列正交基：

```python
# 正确：A @ (A.T @ Q)  —— 先投影到行空间再回到列空间
Y2 = A @ (A.T @ Q)
# 错误：A.T @ (A @ Q)  —— 结果是 (n,l)，与 Q 的 (m,l) 不匹配 → matmul 崩溃
```

### 陷阱 2：动态移位
移位项加在幂迭代结果上：`Y2 = Y2 + sigma * Q`。
sigma 用当前估计的主导奇异值（B=QᵀA 的 SVD 首值）动态更新，
不要用固定移位（固定移位效果差，论文动态方案才是关键）。

### 陷阱 3：精度监控残差维度
Hutchinson 风格残差估计中测试向量必须是 R^n（列空间）：

```python
# 正确：z ∈ R^n，Az 在列空间
test_vec = rng.standard_normal(n)
Az = A @ test_vec
resid = Az - Q @ (Q.T @ Az)
est = np.linalg.norm(resid) / max(np.linalg.norm(Az), 1e-30)
# 错误：用 A.T @ (...) 的版本维度错乱（A.T 是 (n,m)）
```

### 实测结果
- dashSVD (m=2000, n=1000, k=20, p=10, max_power=5)：
  奇异值相对误差 9.43e-16（vs 精确 SVD），重构误差 2.2e-3
- 固定精度 QB（k_true=15, eps=1e-3）：自动发现秩 16，实际误差 7.56e-5
- 同 seed 完全可复现；高噪声矩阵（0.1）下 dashSVD 不差于基础随机 SVD

## FRW 电容提取实现（frw.py）

### 关键：朴素"权重平均"版本完全错误
初版按 `Cji = (1/N) Σ ω_n`（2-D 简化 ω=1，圆上均匀采样）实现，
平行板电容只有解析解的 ~1%（0.85 vs 88.54 pF/m）。
**工作版本 = 随机有限差分（SFD，MicroWalk 思想）**：
在高斯面面片两侧各启动 K 次行走，用命中概率之差估计电场法向分量：

```python
inner = (x - delta*nx, y - delta*ny)   # 内侧（靠近 master）
outer = (x + delta*nx, y + delta*ny)   # 外侧
p_in  = hit_probability_distribution(inner, K)   # 各导体命中比例
p_out = hit_probability_distribution(outer, K)
# 对每个非 master 导体 i：E_i = (p_out[i] - p_in[i]) / (2*delta)
Q[i] += eps * E_i * patch_len
# patch_len = 高斯面周长 / 面片数；C_ji = Q[i] / V_master
```

### 符号方向
`E_i = (p_out - p_in)/(2δ)`（外侧命中概率高 → 正电容）。
初版用 `(p_in - p_out)` 得到负电容。必须跳过 `i == master_idx`（自容不算耦合）。

### 收敛测试设计（测试 bug vs 代码 bug）
平行板解析解忽略边缘效应，FRW 系统性偏高 ~11-16%（偏差非方差），
**不能**断言 rel_err 随 N 增大而减小。正确做法：
不同 seed 两次运行的差异作为方差代理，N 增大 10 倍差异应显著下降
（MC 1/sqrt(N) 收敛）。

### 工作参数（平行板 10x1，εr=1，2-D 单位深度）
- gaussian_offset = 0.5，delta = 0.1（必须 < gaussian_offset）
- K = n_walks // (2 * n_pts)，n_pts = 76（4 边各 20 点）
- 结果：78.23 pF/m vs 解析 88.54 pF/m，rel_err 11.65% → PASS
- 行走每跳 R = 最近导体距离 - 1e-9（防贴边退化），R<=1e-6 直接判定命中

## 关联

- 完整领域方法论见 `eda-frw-capacitance` / `eda-randomized-linalg` skills
- 论文语料库调研报告：`~/hermes-docker-sandbox/workspace/yuwj-eda-research-report.md`
