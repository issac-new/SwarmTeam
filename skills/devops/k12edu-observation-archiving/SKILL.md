---
name: k12edu-observation-archiving
description: "Archive parent observation notes to child-profile.md."
version: 0.1.0
platforms: [macos, linux]
metadata:
  hermes:
    tags: [k12edu, education, child-profile, observation, archiving, cross-validation, wechat, star-ranking]
    related_skills: [k12edu-context-profile-enrichment, k12edu-team-deployment]
---

# K12edu Observation Archiving

> **DRAFT** — Extracted from recurring k12edu-orchestrator work pattern
> (observation-archiving subtasks). Identified by skill-mining cron.

Archive parent-sent observational narratives (received via WeChat) into the
`child-profile.md` living document as **star-ranked, timestamped observation
anchors**. This is distinct from `k12edu-context-profile-enrichment` (which
records *facts* like allergies/budget/routine) — this skill covers the
*narrative observation logging* workflow.

## When to Use

- Mom or Dad sends a child-activity observation via WeChat (port 8651 for mom,
  port 8650 for dad)
- Parent sends a reflective analysis about child development
- Parent corrects a previously-recorded observation (name/age/relation fix)
- Parent provides family event detail (探亲/聚会/旅行) worth archiving
- Two parents provide conflicting or complementary perspectives on same event

## Core Workflow (6 steps)

### Step 1: Identify source and channel

```
Mom WeChat → port 8651 → k12edu-orchestrator account (<k12edu-bot-account-id>@im.bot)
Dad WeChat → port 8650 → orchestrator account (<main-bot-account-id>@im.bot)
```

Record the source parent correctly. **Pitfall**: dad forwards mom's notes
sometimes — content belongs to "妈妈手记" but reply address goes to "爸爸".

### Step 2: Classify star level

| Level | Criteria | Example |
|-------|----------|---------|
| ⭐⭐ | Major developmental reflection, milestone, or behavioral pattern shift | "焦虑双因归因：气质型+环境型" |
| ⭐ | Significant single observation, event detail, or cross-validation entry | "首份爸爸视角带娃观察" |
| (no star) | Minor correction or factual update | "亲戚名字修正" |

### Step 3: Extract structured data

From the narrative, extract:
- **Date** of observation (not date received)
- **Location** of observation
- **Activities** observed
- **Child behaviors** noted
- **Parent's analysis/interpretation**
- **Actionable insights** for teachers
- **Cross-reference points** (does this confirm/contradict prior entries?)

### Step 4: Write as timestamped anchor

```markdown
## ⭐⭐ 2026-08-09（周日）妈妈周日综合反思

### 来源
妈妈通过微信(port 8651)发送

### 核心内容
（结构化摘要，保留原始细节不概括过度）

### 教学影响
（转化为 context-aware-rules.md 中的规则或检查项）

### 交叉验证
（与已有记录的爸爸/妈妈视角对照）
```

### Step 5: Cross-validate multi-parent perspectives

When both parents observe the same child/event:
- **Identify agreement points** (both see same behavior → high confidence)
- **Identify divergence points** (different angles → enrich the picture)
- **Flag unresolved contradictions** for follow-up clarification
- **Record whose perspective is "first"** (e.g. "档案中第一份爸爸视角")

### Step 6: Update dependent files

- `child-profile.md` — add the observation anchor
- `context-aware-rules.md` — if the observation reveals a new constraint
- `child-profile.md` relative tables — if names/ages/relations need correcting

## Common Sub-Patterns

### Sub-pattern A: Name/relation correction

Parent corrects a previously-recorded relative name or relation:
1. Locate ALL occurrences in child-profile.md (grep)
2. Update each occurrence
3. Add a "correction note" explaining what changed
4. Flag any remaining "待确认" items for next interaction

### Sub-pattern B: First-person narrative archiving

Parent sends a detailed first-person observation:
1. Preserve the narrative voice (don't over-summarize)
2. Structure into date/location/activities/analysis sections
3. Star-rank by developmental significance
4. Cross-reference with existing entries

### Sub-pattern C: Extended family event (探亲记录)

Parent reports a family visit/trip with child:
1. Record who was present (names, relations, ages)
2. Record child's interactions with each relative
3. Note unfamiliarity/shyness patterns
4. Extract teaching opportunities (social skills, family bonds)

## Pitfalls

- **Don't over-summarize**: preserve parent's original detail and nuance
- **Don't lose the source attribution**: always record which parent, which port
- **Correction ≠ deletion**: when fixing a name, note what was wrong before
- **Star inflation**: reserve ⭐⭐ for genuine developmental milestones, not every entry
- **Cross-validation takes priority**: when two parents observe same event, the
  combined record is more valuable than either alone

## Related Skills

- **k12edu-context-profile-enrichment** — fact-based incremental enrichment
  (allergies, budget, routine) vs this skill's narrative observation logging
- **k12edu-team-deployment** — initial team creation
