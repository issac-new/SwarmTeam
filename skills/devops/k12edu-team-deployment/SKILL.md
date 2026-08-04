---
name: k12edu-team-deployment
description: "Deploy K12 education teacher teams with context-aware rules."
version: 2.0.0
platforms: [macos, linux]
metadata:
  hermes:
    tags: [k12edu, education, team-deployment, context-aware, weixin, knowledge-base, co-parenting, screen-time, special-education]
    related_skills: [in-session-team-deployment, multi-board-team-deployment, gateway-platform-management, deep-research-workflow]
---

# K12edu Team Deployment

Deploy, extend, and enrich a multi-agent K12 education team (特级家庭教师团队)
on Hermes. Built from the k12edu deployment session (2026-08-01) which created
7 profiles, a shared knowledge index of 628 lines across 12 resource categories,
context-aware rules (416 lines), a living child-profile.md (351 lines),
dual-parent co-parenting, screen-time management, and daily energy curve.

## When to Use

- User asks to build a "特级家庭教师团队" / "education team" / "K12 team" for their child
- User wants to add a specialist teacher (e.g. "怎么没有体育老师?")
- User wants context-aware answers (location + weather + child profile + memory)
- User wants a centralized knowledge base of educational resources
- User provides family background (parents' jobs, commute, vehicles, extended family)
- User provides child daily routine (wake time, nap, bedtime, activities)
- User expresses concern about screen time / electronic devices
- User wants two parents to access the team from separate WeChat accounts

## Step 1 — Initial team deployment

Follow the `in-session-team-deployment` skill for the core pipeline:
1. Create kanban board
2. Scaffold profile dirs + SOUL.md (persona-driven skeleton)
3. Register in profiles.yaml + generate configs (hermes venv python)
4. Second gateway profile with own WeChat account (QR login, .env.common credential scrub)
5. Verify

### Persona-driven SOUL.md skeleton

1. 角色人设 — vivid persona + learner context (age, phase)
2. 平台协议声明
3. 你是谁 — learner profile, tone, stance
4. 教学理念与方法论
5. 年龄适配表
6. 学科专长库
7. 标准作业循环 — kanban_show → recon → design → output → handoff
8. 退出协议 — kanban_complete/kanban_block
9. 前线侦察协议 — session_search + hindsight_recall
10. 安全红线
11. 具体操作命令手册 — REAL hermes CLI commands
12. 共享规则 — pointer to _shared/

## Step 2 — Team extension by splitting overloaded profiles

**Signal**: user identifies a missing specialist ("怎么没有体育老师?").

1. **Create new specialist**: mkdir + clone sibling config.yaml (string-replace
   profile name in `environment_hint` and `default_assignee`) → write SOUL.md
2. **Rename/trim overloaded profile**: patch SOUL.md to drop the split-out domain.
   Add: "XX相关内容由专职导师 <new-profile> 负责."
3. **Update routing in 3 places**: routing-rules.md keyword table + assignee table,
   router SOUL.md resource→teacher table, profiles.yaml (clone sibling block)
4. **Verify**: `grep -c "<new>" profiles.yaml` + `wc -l profiles/<new>/SOUL.md`

## Step 3 — Context-aware rules layer (3 files)

### context-aware-rules.md (grows to ~400+ lines)

A 🔴 mandatory rules file every teacher SOUL.md references. Add chapters
incrementally as the user provides info:

- **Location anchoring**: city + district + community → local resources,
  climate, education environment. Layer by transport (e-bike ≤5km vs car 5-20km).
- **Weather sensing**: `curl -s "wttr.in/<City>?format=%C+%t+%h+%w&lang=zh"`
  + decision table (sunny→outdoor, rain→indoor, heat≥32℃→avoid, AQI≥150→no outdoor)
- **Trending events**: priority tiers + fetch methods
- **Child profile updates**: trigger conditions
- **Memory persistence**: hindsight_retain/hindsight_recall norms
- **Safety red lines**: weather, location, age, privacy, professional boundary
- **Screen time management** (Step 7)
- **Dual-parent co-parenting** (Step 8)
- **Pre-answer checklist**: grows from 6→8 items

### child-profile.md (grows to ~350+ lines)

Structured child档案 accumulating detail as user provides it:
- Basic info, parent profiles, family geography and commute, transport
- Extended family, dual-culture heritage
- Daily routine and energy curve, interests with attitude markers (✅⚠️🔴)
- Electronic device patterns, developmental milestones, teaching progress
- Parent interaction log (timeline), family education division, special attention

### Teacher SOUL.md snippet (5-6 bullet 🔴 block, before first ##)

```
## 🔴 情境感知强制规则
> 不可跳过。每次回答前必须执行。
1. 地点锚定: 家庭在<City>
2. 天气感知: curl wttr.in/<City>
3. 孩子档案: 更新 references/child-profile.md
4. 持续记忆: hindsight_retain / hindsight_recall
5. 完整规则: 见 references/context-aware-rules.md
6. 爸爸妈妈协同: (if dual-parent — Step 8)
```

## Step 4 — Shared knowledge index (centralized catalog)

ONE index file: `references/<topic>-index.md` on the router profile.
- Start with one category, append sections per research round (238→628 lines, 12 categories)
- Each teacher SOUL.md gets ~40-line domain section referencing the shared index

### Research workflow

Dispatch parallel `delegate_task` subagents (GitHub/CN video/international courses,
special ed, lesson plans, competitions, books, journals, encyclopedias, classics).
Results land as /tmp/*.md → orchestrator integrates into index + patches teacher SOULs.

> ⚠️ **max_concurrent_children=3**: delegate_task batch allows 3 concurrent. For 4+
> tasks, split into two calls or combine related topics.

### Pitfalls
- **DeepSeek 402 quota**: subagents on deepseek-v4-flash die immediately. Re-dispatch with main model.
- **Subagent iteration limits (50+ calls)**: data survives in `subagent-summary-*.txt`. Read → write_file manually.
- **Wikipedia/Google blocked in CN**: use 360搜索 (so.com) for Chinese, 豆瓣 for books, curl for URL probing.
- **Bing RSS Chinese tokenization**: splits Chinese titles into chars. Use 豆瓣主站搜索.

## Step 5 — Special education safety red line

```
## 特殊教育安全红线
> 🔴 强制规则：不可跳过，不可降级为建议。
1. 必须建议专业评估（儿保科/儿童精神科/言语治疗师）
2. AI教师补充但不替代专业诊断和康复治疗
3. 不做医学诊断，不开具干预方案
4. 引用干预方法必须注明证据等级和来源
5. 路由到 <character-teacher> 处理此类问题
```

Evidence-based methods: ESDM (Dawson 2010 PMID 19948568), TEACCH (Zeng 2021
PMID 33962129), Hanen (PMID 32003252), PECS (Bondy 2001), NCAEP (Steinbrenner 2020).

> **Sensory integration (感统课)**: child attending 感统课 signals developmental
> needs. Route to k12-physical for complementary home sensory activities + monitor milestones.

## Step 6 — Enriching child-profile incrementally

Each family detail becomes a teaching constraint:

| User provides | Profile section | Teaching impact |
|---------------|----------------|-----------------|
| Parents' jobs/education | Parent profiles | Leverage expertise (engineer→STEM, ed-major→reading) |
| One parent travels | Commute table + schedule | Route activities by who's home |
| Only one parent drives | Transport constraints | Layer by car vs e-bike; note non-driver can't "just drive" |
| Extended family locations | Extended family table | Near=frequent interaction; far=child unfamiliar, prep with photos/books |
| Dual-culture heritage | Family culture note | Both cultures as teaching material |
| Child's school/extracurriculars | Daily routine table | Know where child is each time block |

### Commute-aware scheduling (traveling parent)

```
| Day | Parent status | Teaching adjustment |
| Mon-Thu | ❌ away | Home parent leads |
| Fri eve | 🚄 returns | Welcome-home bonding |
| Sat | ⭐ both home | Push traveling parent's strengths |
| Sun eve | 🚄 leaves | Video-call goodbye |
```
Add checklist item: "□ Check day of week — traveling parent home?"

### Transport layering (specific vehicles)

```
| ≤3km | ⭐ e-bike/walk | ≤5km | ⭐ e-bike |
| 5-10km | Car | 10-20km | Car | >20km | Car+planning |
```

## Step 7 — Screen time management rules (NEW)

When user says "喜欢玩手机/看电视/玩iPad" + "严格控制电子设备时间":

### Add dedicated chapter to context-aware-rules.md:

```
## 电子设备管理规则
> 🔴 家长明确要求：严格控制。不可降级。

### Teacher rules:
□ Don't recommend activities that increase screen time
□ Educational apps only, time-limited (Code.org 20min)
□ Device craving → MUST provide 2-3 non-electronic alternatives
□ Reinforce existing positive habits (e.g. bookstore reading)
□ Arcade: read 30min → limited gaming → outdoor play
□ AAP: ≤1hr/day quality screen time for age 5, co-viewed

### Substitution table:
| Phone → outdoor sports/crafts/books |
| TV → shared reading/role-play/chores |
| iPad → board games/experiments/drawing |
```

Add checklist: "□ Does this recommendation increase screen time?"
Child-profile interest table gets ✅⚠️🔴 attitude markers.

## Step 8 — Dual-parent co-parenting (NEW)

Two parents via separate WeChat → separate gateways → SAME shared files
(child-profile.md, hindsight, kanban board). The shared files ARE the integration.

### Add chapter to context-aware-rules.md:

```
## 爸爸妈妈协同规则
### Pre-answer checklist (8 items):
□ 1. Identify current parent (mom=edu-gateway / dad=main-gateway route)
□ 2. Review other parent's recent interactions
□ 3. Check progress to sync
□ 4. Check philosophy misalignment
□ 5. Check day of week (traveling parent?)
□ 6. Check extended family (cousins? grandparents?)
□ 7. Check current TIME and child energy state
□ 8. Update interaction log

### 5 rules: cross-reference, progress sync, philosophy alignment,
### labor division by strengths, privacy (no judging in front of other)
```

Child-profile.md gets: parent profiles, interaction log (timeline table),
family education division table (6 domains → lead parent → rationale).

Each teacher SOUL.md gets bullet 6: "爸爸妈妈协同: 回顾互动记录, 交叉引用, 主动同步进展"

## Step 9 — Child daily routine & energy curve (NEW)

When user provides sleep schedule (e.g. "06:30起床, 不午睡, 21:30入睡"):

### Build energy curve table in child-profile.md:

```
| Time | Energy | Suitable | Avoid |
| 06:30-09:00 | ⭐⭐⭐ peak | new cognitive input (reading/math/English) | — |
| 16:30+ | ⚠️ tired | light outdoor/free play | high-intensity learning |
| 20:30+ | 😴 | quiet reading/storytime | 🔴 ALL electronic devices |
```

### Time-based rules:
- 🔴 No nap: don't recommend "after nap, do X"
- 🟢 Morning post-wake = golden cognitive window
- 🟡 Post-extracurricular = may be fatigued, gentle activities
- 🔴 1hr before bedtime = NO screens (blue light suppresses melatonin)
- 🔴 Bedtime = hard stop; evening activities end 1hr before

Add checklist: "□ Check current time and child's energy state"

## Related Skills

- **in-session-team-deployment** — core pipeline (default profile)
- **multi-board-team-deployment** — CLI batch creation
- **gateway-platform-management** — WeChat/second gateway
- **deep-research-workflow** — parallel research subagents
- **research-then-improve** — research→gap→propose cycle