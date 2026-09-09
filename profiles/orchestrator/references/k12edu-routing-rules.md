# K12 教育看板路由规则

## 概述

k12edu 看板为用户的儿子（2020年2月出生）提供特级家庭教师团队服务。调度权统一在主 orchestrator（可跨 board 直接 `kanban_create(board="k12edu", assignee="k12-xxx")`）；k12edu-orchestrator 为领域网关延伸，通过第二个微信号接入，负责 k12 领域上下文与日常消息路由。

## 关键词判定

当消息中出现以下关键词时，路由到 k12edu 看板：

### 学科类
- **国学/语文**: 唐诗、宋词、三字经、弟子规、识字、写字、书法、成语、故事、国学
- **数学/科学**: 数学、数字、加减法、形状、逻辑、实验、科学、自然、观察、为什么
- **语言/英语**: 英语、单词、双语、绘本、阅读、讲故事、表达、口语
- **艺术/手工**: 画画、绘画、手工、折纸、音乐、唱歌、跳舞、审美、色彩
- **体育/运动**: 运动、体能、跑跳、游泳、球类、平衡车、跳绳、感统、户外
- **品格/心理**: 情绪、脾气、分享、礼貌、习惯、专注力、社交、朋友、害怕、胆怯

### 成长类
- 入学准备、幼小衔接、学前班、幼儿园、小学
- 生长发育、注意力、兴趣培养
- 亲子关系、教育方法、管教

## 教师分配表

| 关键词领域 | assignee | profile |
|-----------|----------|---------|
| 国学/诗词/书法/传统文化 | k12-chinese | 国学大师 |
| 数学/科学/逻辑/实验 | k12-stem | 科学启蒙导师 |
| 英语/双语/阅读/表达 | k12-language | 语言发展专家 |
| 美术/音乐/手工/审美 | k12-arts | 艺术导师 |
| 体育/运动/感统/户外/球类 | k12-physical | 体育导师 |
| 品格/情绪/社交/习惯 | k12-character | 品格心理导师 |
| 综合教育咨询/家长提问 | k12edu-orchestrator | 教育调度路由器 |

## 特殊路由规则

1. **家长咨询**：当家长（非孩子）提问教育方法时，路由到 k12edu-orchestrator 综合回答
2. **多学科交叉**：一个问题涉及多学科时，k12edu-orchestrator 创建多个子任务并行分配
3. **年龄适配**：所有教师 profile 的 SOUL.md 已内置年龄适配表（4-12岁动态调整），无需额外路由
4. **安全红线**：所有教师禁止分享孩子个人信息、禁止推荐未经家长批准的外部服务

## 网关架构（独立性仅限网关层）

- k12edu-orchestrator 运行独立 gateway 进程（HERMES_HOME=~/.hermes/profiles/k12edu-orchestrator），**网关层独立**以独占第二微信号
- api_server port: 8651（与主集群 8650 分离）
- weixin channel: 第二个微信账号（通过 QR 登录配置）
- kanban board: k12edu（通过 get_default_hermes_root() 共享 ~/.hermes/kanban/boards/k12edu/），**调度权不独立**——主 orchestrator 可跨 board 建卡分配
- dispatcher: 内嵌在 k12edu gateway 中，每 60 秒 tick（两个 gateway 各自 tick 同一 k12edu 看板，互不冲突，因 dispatcher 按 assignee profile 派发）
