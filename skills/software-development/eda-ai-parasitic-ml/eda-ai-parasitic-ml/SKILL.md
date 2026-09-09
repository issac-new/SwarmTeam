---
name: eda-ai-parasitic-ml
description: >-
  AI for EDA 寄生参数机器学习 — CNN-Cap 卷积电容模型、CircuitGPS few-shot 异质图
  学习、CircuitGCL 图对比学习、NAS 电容 CNN、DeepRWCap 神经引导随机行走。
  基于喻文健方法体系（TODAES'23 + DATE'24/25 + ICCAD'25 + AAAI'26 + GLSVLSI'24）。
  Use when implementing ML-based parasitic capacitance prediction or
  neural-guided field solvers.
version: 1.0.0
platforms: [macos, linux]
metadata:
  hermes:
    tags: [eda, ai, machine-learning, cnn, few-shot, graph-learning, capacitance, parasitic]
    related_skills:
      - eda-frw-capacitance
      - eda-platform-development
      - eda-randomized-linalg
---

# AI for EDA 寄生参数机器学习（ML Parasitic Extraction）

用机器学习预测/加速寄生电容提取。方法体系来自喻文健 Numbda 课题组，
是 ML for EDA 在寄生提取方向最系统的成果线。

## 何时使用

- 全芯片级电容提取的 ML 加速（替代/补充 pattern matching）
- AMS 电路寄生预测（数据稀缺场景）
- SRAM/标准单元预布局电容快速估计
- 神经引导随机行走求解器（ML+MC 混合）

## 核心原理

### 1. CNN-Cap 卷积电容模型（J08, TODAES'23）
- **网格表示法**（novel grid-based data representation）：
  - 2-D：版图窗口 → 像素网格（导体/介质/空气通道编码）
  - 3-D：3-D 窗口 → 体素网格，可变导体数
  - 消除 pattern matching 的离散 pattern 爆炸
- **ResNet 架构**：捕获空间信息，优于 MLP 电容模型
- **训练技巧**：数据增强、损失加权（总电容 vs 耦合电容侧重不同）
- **精度**：2-D 总电容误差 < 1.3%；耦合电容 99.5% 概率 < 10%；
  3-D 总电容 99% 概率 < 5%，最大 7.7%
- **速度**：GPU 比 Raphael 快 4000×（2-D）/ 12000×（3-D），内存可忽略

### 2. NAS-CNN（date24, DATE'24）
- 神经架构搜索训练 3-D 电容 CNN：Normal Cell + Reduction Cell
- 自动发现比人工设计更好的 CNN 架构

### 3. CircuitGPS few-shot 学习（C46, DATE'24）
- AMS 电路数据稀缺 → few-shot learning
- 电路网表 → **异质图**（器件类型/连接关系节点，耦合电容建模为链路）
- 预训练：链路预测（link prediction）→ 微调：边回归（edge regression）
- 小跳采样（small-hop sampling）：转换链路/节点到局部子图

### 4. CircuitGCL 图对比学习（iccad252, ICCAD'25）
- 图对比学习 + 表示散射（representation scattering）+ 标签重平衡
- 解决：数据稀缺、标签分布不均、电路实现多样性
- 跨异构电路的可迁移寄生估计

### 5. DeepRWCap 神经引导随机行走（aaai26, AAAI'26）
- ML 引导 MC 随机行走：神经网络预测行走方向/终止概率
- 减少 FRW 方差 → 收敛更快
- 与 FRW 求解器无缝集成（见 eda-frw-capacitance skill）

### 6. 应用线
- SRAM 预布局电容预测（glsvlsi24, GLSVLSI'24）：版图前预测，加速设计收敛
- 薄膜参数 ML 预测（integration26）：半导体工艺介电沉积优化
- ParasGB（ICCAD'26）：AMS 电路寄生估计图基准套件

## 标准实现步骤

```python
# CNN-Cap 2-D 模型（J08 结构）
def build_cnn_cap_2d(input_channels=3, num_convs=8):
    """2-D 版图窗口 → 总电容/耦合电容预测"""
    import torch.nn as nn
    layers = []
    in_ch = input_channels
    # 多级卷积（类似 ResNet 残差块）
    for _ in range(num_convs):
        layers.append(nn.Conv2d(in_ch, 64, 3, padding=1))
        layers.append(nn.BatchNorm2d(64))
        layers.append(nn.ReLU())
        in_ch = 64
    return nn.Sequential(*layers, nn.AdaptiveAvgPool2d(1),
                         nn.Flatten(), nn.Linear(64, 1))

# 数据表示：2-D 窗口网格化
def window_to_grid(layout_window, grid_size=64):
    """版图窗口 → 多通道网格（导体/介质/边界编码）"""
    # channel 0: 导体存在性
    # channel 1: 介质类型
    # channel 2: 距最近导体距离（可选）
    ...

# CircuitGPS 两阶段（C46）
def circuit_gps_train(graphs, val_graphs):
    """预训练链路预测 → 微调边回归"""
    # Stage 1: link prediction 预训练（GNN encoder + link decoder）
    # Stage 2: 用目标电路少量标注微调 edge regression head
    ...

# DeepRWCap（aaai26）：神经引导 FRW
def deep_rwcap_walk(master_net, gnn):
    """GNN 预测行走策略，指导 FRW 采样"""
    # 每跳：GNN 输入当前点局部结构 → 输出转移分布偏移
    # 与 FRW 方差缩减结合
    ...
```

## 验证命令

```bash
# CNN-Cap 精度验证协议（J08 报告指标）
# 1. 测试集总电容相对误差 < 1.3%（2-D）/ 5%（3-D, 99% 概率）
# 2. 耦合电容误差 < 10%（99.5% 概率）
# 3. 与 field solver（Raphael/BEM/FRW）对比
python -c "
import numpy as np
# 误差分布检查
errs = np.abs(y_pred - y_true)/y_true
print(f'total-cap mean rel err: {errs.mean():.4f}')
print(f'p99: {np.percentile(errs, 99):.4f}')"

# CircuitGPS 评估：k-shot 设置（5-shot/10-shot），
# 微调后 R2/MAE 应明显优于零样本基线
```

## 常见陷阱

1. **网格分辨率**：太粗丢失几何细节，太细显存爆炸——需扫描
2. **数据生成成本**：训练数据来自 field solver，生成慢——预表征缓存复用
3. **3-D 体素方向**：Z 方向（层）分辨率必须足够（介电层边界）
4. **few-shot 类别不平衡**：耦合电容分布长尾——重平衡（CircuitGCL 思路）
5. **ML 不能替代 sign-off**：ML 预测必须与 field solver 交叉验证，
   超出训练分布（新工艺/新结构）要回退到确定性求解器
6. **图表示**：异质图边类型必须包含器件类型，否则 GNN 无法区分
7. **seed 固定**：训练/采样必须固定 seed 可复现

## 参考论文（全部在本地语料库）

- J08 CNN-Cap (TODAES'23)
- date24 NAS-CNN (DATE'24)
- C46 CircuitGPS (DATE'24)
- iccad252 CircuitGCL (ICCAD'25)
- glsvlsi24 SRAM 预布局 (GLSVLSI'24)
- aaai26 DeepRWCap (AAAI'26) / arXiv_2511.06831
- integration26 薄膜参数 (Integration'26)
- iccad261 ParasGB (ICCAD'26)
- iccad251 Flash-CNNCap (ICCAD'26) / dac261 AttentionCap (DAC'26) / dac262 CapBench (DAC'26)

## 与其他 skill 的关系

- `eda-frw-capacitance`：DeepRWCap 是其神经引导扩展；ML 模型需要 FRW/
  BEM 生成训练数据
- `eda-platform-development`：eda-platform ai/ 模块扩展方向
- `eda-randomized-linalg`：训练数据生成中的 SVD/PCA 预处理
