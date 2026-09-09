# PDN / Eye / Hypergraph / CNN-Cap 实现笔记（本轮验证）

实现模块：`signal/pdn.py`（R-MATEX 指数积分、波形压缩、阶跃响应眼图）、
`ipcore/hypergraph.py`（BlasPart、MCMCF）、`ai/cnn_cap.py`（CNN-Cap 网格表示）。
全部通过 ad-hoc 验证 + 全套 192 pytest（2026-07-31）。

## 1. R-MATEX 指数积分 — φ1 计算的最大坑（已修复）

**错误做法**（曾导致单节点 RC 超调 8-20 倍）：
```python
phi1_b = (expm(hA) @ b - b) / h   # 错！丢失一阶项 h·b
v_new = v + h * phi1_b
```
`(exp(hA)−I)·b ≈ hA·b` 只含二阶起，一阶项 `h·b` 丢了，数值上表现为
指数级超调（单节点 RC h=1e-4 时 v_num=0.95 vs exact 0.63）。

**正确公式**（Al-Mohy & Higham 2011，增广矩阵法）：
```
v(t+h) = e^{hA}·v(t) + h·φ1(hA)·b        # A = -C⁻¹G, b = C⁻¹i(t)
       = [I, 0] · exp(h·[[A, b],[0, 0]]) · [v(t); 1]
```
实现：对 (n+1) 维增广矩阵 `A_bar = [[A, b],[0,0]]` 做 Arnoldi，
`w0 = [v(t); 1]`，一次 Krylov 同时得到两项，然后 `w_next[:n]`。
小矩阵 `expm(h·H_m)` 用 scipy.linalg.expm。

验证：RC 链（10 节点，R=1, C=1e-3）vs 梯形积分参考 → rel_err=1.52e-4 (<1% PASS)。

**调试技巧**：先用**单节点 RC**（解析解 v(t)=(i/G)(1−e^{−Gt/C})）隔离 Krylov 收敛
问题——若单节点都超调，是公式错误而非子空间维度不足。

## 2. 阶跃响应眼图预测（step_response_eye）— 三个坑

1. **脉冲响应方向**：`p(t) = h(t) − h(t−UI)` 必须**前补零**：
   `h_padded = concat(zeros(n_ui), h_resp)`，然后
   `pulse = h_padded[n_ui:n_ui+len] − h_padded[:len]`。
   反向（后补零）会得到镜像脉冲，眼图恒闭（eye=0）。
2. **采样点避开跳变沿**：不要在整 UI 上取 percentile——理想脉冲的边缘
   0/1 采样混入导致 high_min=0。取 UI **中央 60% 段**
   `margin = max(1, n_ui//5)`，slice `center+margin : center+n_ui−margin`。
3. **high/low 分离**：phase1（0101…，中央位=1）只贡献 high，phase0（1010…，
   中央位=0）只贡献 low。混在一起取 percentile 会互相污染：
   ```python
   high_min = np.percentile(resp1[eye_slice], 5)
   low_max  = np.percentile(resp0[eye_slice], 95)
   eye_height = max(high_min - low_max, 0)
   ```
   eye_width 用 resp1 中央段高于 mid 的比例（1 位稳定宽度）。

验证：理想瞬跳阶跃 → h=1.00, w=1.00；RC 慢上升（τ=5UI）→ w=0.33。物理趋势正确。

## 3. BlasPart 贪心初始化 bug（已修复）

**错误**：`if w[0] <= w[1]: partition[v]=0` —— 相等时恒选 0，全部顶点涌向
part 0，balance 可达 1.33+（demo 断言 1.2 失败）。

**修复**（目标驱动，向 total/2 收敛）：
```python
if w[0] + w_v <= total/2 or w[0] + 1e-12 < w[1]:
    partition[v] = 0
else:
    partition[v] = 1
```
要点：`<= total/2` 保证最终两侧 ≈ 平衡；`<` 严格比较打破相等死循环。
验证：6 顶点 demo → balance=1.000, cut=3, 确定性同 seed 一致。

## 4. CNN-Cap 网格表示（J08）

- `layout_to_grid_2d`: 3 通道 (H,W) 网格 — 导体存在/介质类型/最近导体距离。
- 线性基线（NumPy 岭回归）验证管线：200 平行板样本（W∈[0.3,0.9],
  gap∈[0.05,0.3]），mean_rel_err=4.0%，p99=11.9%（线性基线可接受；
  生产用 PyTorch ResNet）。
- **物理趋势测试**：小 gap → 大电容（模型必须学到，否则数据表示有 bug）。

## 5. 验证策略总结（该平台数值模块）

| 模块 | 参考解 | 阈值 |
|------|--------|------|
| R-MATEX PDN | 梯形积分（同网格） | rel_err < 1% |
| FRW 电容 | 平行板解析 C=εW/d | rel_err < 15%（含边缘效应） |
| FRW 收敛 | seed-spread 代理（非解析误差缩小） | N×10 → spread < 0.8× |
| 眼图 | 物理趋势（理想开/损耗闭） | h>0.3, w 对比 |
| BlasPart | 确定性 + 平衡 + cut 上界 | balance ≤ 1.2 |
| CNN-Cap | 线性基线 + 物理趋势 | mean < 15% |
| dashSVD | 精确 np.linalg.svd | sv_err < 1e-2 |

通用：**随机算法固定 seed**（可复现性红线）；**MC 收敛性测试不要用
"解析误差随 N 缩小"**（解析解可能含系统偏差如边缘效应），改用
不同 seed 两次运行的 spread 作为方差代理。
