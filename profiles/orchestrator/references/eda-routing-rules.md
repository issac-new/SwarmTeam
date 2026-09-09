# EDA 看板路由规则

## §0.5.9 EDA 关键词表

| 关键词 | 路由目标 assignee | 说明 |
|--------|------------------|------|
| EDA, 电子设计自动化, 芯片设计 | eda-physics | EDA 通用 |
| FDTD, FEM, 有限元, FDTD, Yee网格, PML | eda-physics | 物理建模 |
| PDE, 偏微分方程, Navier-Stokes, 麦克斯韦 | eda-physics | PDE 求解 |
| 信号完整性, SI/PI, S参数, Smith圆图 | eda-toolchain | 信号完整性 |
| 眼图, PRBS, BER, PDN, 阻抗谱 | eda-toolchain | 信号完整性 |
| 芯片布局, die, 布局可视化 | eda-toolchain | 芯片布局 |
| 光子计算, DONN, 衍射光学, ONE架构 | eda-optics | 光学计算 |
| Fresnel, 衍射传播, 光学神经网络 | eda-optics | 光学仿真 |
| RISC-V, IP核, RV32IMC, Verilog | eda-ipcore | IP核设计 |
| AES, SM4, 国密, TRNG, PUF | eda-ipcore | 加密IP核 |
| 综合, Yosys, nextpnr, Verilator | eda-ipcore | 仿真综合 |
| 多物理场, 耦合场, 热-力, 电磁-热 | eda-multiphysics | 多物理场 |
| 拓扑优化, SIMP, 自适应网格 | eda-multiphysics | FEM框架 |
| Newmark, WKB, 量子隧穿, 振动 | eda-multiphysics | 特殊物理场 |
| FNO, 神经算子, DeepONet, PINN | eda-ai | AI+EDA |
| AlphaChip, 强化学习布局, cuLitho | eda-ai | AI芯片设计 |
| DeepXDE, neuraloperator, PINNs | eda-ai | PDE神经算子 |

## EDA 看板 assignee 自动分配

| assignee | 角色 | 典型任务 |
|----------|------|---------|
| eda-physics | 物理建模工程师 | FDTD/FEM/PDE 求解器实现 |
| eda-toolchain | EDA工具链工程师 | SI/PI分析/Smith圆图/眼图/芯片布局 |
| eda-optics | 光学计算工程师 | DONN/Fresnel传播/ONE分治框架 |
| eda-ipcore | IP核工程师 | RISC-V/AES/SM4/TRNG/PUF |
| eda-multiphysics | 多物理场工程师 | 10种物理场/耦合场/FEM框架/SIMP |
| eda-ai | AI+EDA工程师 | FNO/DeepONet/PINNs/AlphaChip |

## EDA 看板 profile_scope

```
orchestrator, eda-physics, eda-optics, eda-toolchain, eda-ipcore, eda-multiphysics, eda-ai
```

## 任务创建模板

```python
kanban_create(
    title="实现 FDTD 2D 电磁场求解器",
    assignee="eda-physics",
    board="eda",
    workspace_kind="worktree",
    body="""
## 任务
实现 2D FDTD 电磁场求解器，支持 Yee 网格、PML 吸收边界、平面波源。

## 验收标准
1. 平面波传播与解析解误差 < 1e-4
2. PML 边界反射 < -60dB
3. Courant 稳定性条件满足
4. 单元测试覆盖率 > 80%

## 技术参考
- flaport/fdtd (⭐711): Python FDTD 参考实现
- NanoComp/meep (⭐1720): FDTD 行业标杆
- 调研报告: workspace/eda-tech-deep-dive.md §1
"""
)
```
