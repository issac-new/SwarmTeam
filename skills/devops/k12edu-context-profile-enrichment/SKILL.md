---
name: k12edu-context-profile-enrichment
description: "Enrich K12 team child-profile with family detail."
version: 1.0.0
platforms: [macos, linux]
metadata:
  hermes:
    tags: [k12edu, education, child-profile, context-aware, family-background, co-parenting, budget, allergy, energy-curve]
    related_skills: [k12edu-team-deployment, k12-family-area-survey, in-session-team-deployment]
---

# K12edu Context Profile Enrichment

Progressively enrich the `child-profile.md` and `context-aware-rules.md` files
of a deployed K12 education team as the user provides incremental family detail.
Each detail becomes a **teaching constraint** that makes the AI teachers'
recommendations increasingly personalized and safe.

> **Companion to `k12edu-team-deployment`** (which covers initial team creation).
> This skill covers the **ongoing enrichment** phase that follows deployment.

## When to Use

- User provides family background AFTER the k12edu team already exists
- User mentions parent jobs, education, commute, vehicles, driving ability
- User mentions extended family (aunts, uncles, cousins, ages, locations)
- User provides child daily routine (wake/nap/bedtime)
- User mentions food allergies or dietary restrictions
- User mentions child interests, favorite shows, personality traits
- User provides budget constraints for activities
- User mentions weekend travel preferences
- User corrects an assumption about the family (e.g. "爸爸不会开车")
- User refines activity preferences (e.g. "孩子人文类不太懂" → then "博物馆孩子喜欢")

## Core Principle: Each Detail = A Teaching Constraint

Every piece of family information should be:
1. **Recorded** in `child-profile.md` (the living档案)
2. **Converted to a rule** in `context-aware-rules.md` (how teachers should adapt)
3. **Cross-referenced** in the relevant teacher SOUL.md sections

## Enrichment Patterns (by information type)

### Pattern 1: Parent profiles and expertise

```
User says: "爸爸是北邮本科计算机工程师，妈妈是北师大硕士全职带孩子"
→ child-profile.md: parent profiles table (job/education/availability/strengths)
→ teaching impact: weekend dad → STEM/science; weekday mom → reading/emotion/character
```

### Pattern 2: Commute and driving constraints

```
User says: "爸爸不会开车" + "妈妈有电动车和SUV，更喜欢骑电动车"
→ child-profile.md: transport table with "妈妈开" notation
→ context-aware-rules.md: transport layering (e-bike ≤5km vs SUV 5-20km)
→ 🔴 rule: ALL driving requires mom; dad-alone activities limited to walk/e-bike/taxi
```

**⚠️ Pitfall**: The initial `k12edu-team-deployment` skill assumes "Fri eve =
welcome-home bonding" for traveling parents. If the parent arrives LATE
(post-bedtime) or works overtime, CORRECT immediately:
- Fri eve → 🔴 no "wait for dad" activities; do not disturb sleeping family
- Sat morning → parent sleeps in; activities start at 9:00+ not 8:00
- Active-parent window = Sat afternoon + Sun daytime only

### Pattern 3: Extended family mapping

```
User says: "大姨的儿子小宇高一，女儿曼曼大三在济南；姑姑家西安大儿子高一..."
→ child-profile.md: extended family table split by:
  - Mom's side (near, frequent interaction)
  - Dad's side (far, child unfamiliar)
  - Age/grade for each cousin
→ Identify near-age playmates (closest in age = best potential playmate)
→ Flag unfamiliarity: "child doesn't know dad's side relatives well"
→ Teaching: prep child with photos/books before distant relatives visit
```

### Pattern 4: Social dynamics and willingness

```
User says: "堂姐不太愿意带孩子互动，但妈妈愿意承担经济开销"
→ child-profile.md: social dynamics note with ⚠️ marker
→ context-aware-rules.md: strategy for reluctant-relative interactions:
  - Mom covers costs to reduce their burden
  - Leverage geographic convenience (e.g. same area as extracurriculars)
  - If refused multiple times, don't push — maintain natural relationship
```

### Pattern 5: Daily routine and energy curve

```
User says: "06:30起床, 不午睡, 21:30入睡"
→ child-profile.md: hourly schedule table + energy curve
→ context-aware-rules.md: time-based rules:
  - 🔴 No nap: don't recommend "after nap" activities
  - 🟢 Morning (06:30-09:00) = golden cognitive window
  - 🟡 Evening (16:30+) = may be fatigued, gentle activities
  - 🔴 1hr before bedtime = NO screens (blue light)
  - 🔴 Bedtime = hard stop
→ Add checklist item: "□ Check current time and child energy state"
```

### Pattern 6: Home parent weekly energy decline

```
User says: "妈妈一个人看孩子很累，周四肢五精力跟不上"
→ child-profile.md: weekly energy table (Mon ⭐⭐⭐ → Fri ⚠️⚠️)
→ context-aware-rules.md: day-of-week adaptive recommendations:
  - Thu/Fri → recommend child-independent activities (puzzles/audiobooks)
  - Mom overwhelmed → empathize + validate ("您已经做得很好了")
  - Child extra naughty Thu/Fri → normal (child senses mom's fatigue)
```

### Pattern 7: Food allergies (SAFETY RED LINE)

```
User says: "孩子对鸡蛋和奶制品过敏，喜欢吃冰淇淋和蛋糕"
→ child-profile.md: allergy table (allergen/severity/favorite-affected-foods)
→ context-aware-rules.md: add safety red line #N:
  "🔴 食物过敏: 孩子对XX过敏！涉及食物/零食/奖励/生日/烘焙时必须检查过敏原"
→ Build substitution table: ice cream → coconut-milk ice/fruit smoothie
→ Special scenarios: birthday parties, grandparent meals, cousin snacks
```

### Pattern 8: Budget constraints

```
User says: "本地≤200/天，旅游≤600/天（不含食宿往返），偶尔超没关系，上限1000"
→ child-profile.md: budget table with 3 tiers (routine/occasional/absolute-ceiling)
→ context-aware-rules.md: budget rules:
  - Local ≤200/day, travel ≤600/day (excl. food/lodging/transport)
  - Occasional overrun OK, absolute ceiling 1000/day
  - Free activities still preferred (museums/parks/libraries)
  - Over-budget activities: label price, let parent decide
  - >1000: don't recommend (unless birthday/travel special occasion)
```

### Pattern 9: Activity preference refinement (ITERATIVE CORRECTION)

```
Initial: "妈妈喜欢户外，孩子人文类不太懂"
→ First pass: demote museums/historical sites to ⭐ (low priority)
→ User corrects: "博物馆和科技馆孩子是喜欢去看的"
→ CORRECT: museums/science centers ≠ pure historical sites
  - Museums/science centers: ⭐⭐⭐ (child likes dinosaurs/interactive exhibits)
  - Pure historical sites/stele/artifacts: ⭐ (child doesn't understand, needs storytelling)
→ Build "outdoor-wrapping" strategy: use outdoor elements to package cultural content
  (museum → dinosaur hall + lawn picnic; 千佛山 → hiking + city view)
```

**⚠️ Pitfall**: Don't over-generalize "child doesn't understand humanities" to
mean "child doesn't like museums." Museums have dinosaurs, animals, interactive
exhibits that children DO understand. Distinguish **interactive/kid-friendly
venues** from **pure cultural heritage sites**.

### Pattern 10: Weekend intra-province travel

```
User says: "周末可以适当在省内高铁旅游"
→ child-profile.md: HSR-reachable cities table (destination/time/highlights/teaching-fit)
→ context-aware-rules.md: travel strategy:
  - Best timing: Sat-Sun when traveling parent is home
  - Budget: ≤600/day (excl. food/lodging/HSR tickets)
  - Prefer destinations matching child's interests (space/ocean/nature)
  - Loose itinerary: 1-2 attractions/day (child doesn't nap, limited stamina)
  - Combine with family visits (e.g. 莘县 to see grandparents)
  - Sun return: leave time for dropping traveling parent at HSR station
```

### Pattern 11: Child personality and interests

```
User says: "孩子淘气赖皮，喜欢太空/航天/星座，在看小小牛顿，喜欢布鲁伊"
→ child-profile.md: 
  - Personality table (trait/manifestation/teacher-response)
  - Interest table with ✅⚠️🔴 attitude markers
  - Current reading list
  - TV/video content management (educational value rating per show)
→ context-aware-rules.md: leverage interests as teaching hooks
  (space interest → k12-stem math/science; hero shows → character lessons)
→ Diet: "喜欢吃肉不喜欢青菜" → creative vegetable strategies
```

## Enrichment Workflow

1. **Patch child-profile.md**: add/update the relevant section
2. **Patch context-aware-rules.md**: add/update the corresponding rule or safety red line
3. **Update the pre-answer checklist** if the new info requires a new check
4. **hindsight_retain** the new information with appropriate tags
5. **Verify**: grep keywords in both files to confirm the patch landed

## File Growth Pattern

| Session phase | child-profile.md | context-aware-rules.md |
|---------------|-----------------|----------------------|
| Initial deploy | ~100 lines | ~250 lines |
| + Family background | ~250 lines | ~350 lines |
| + Routine + allergy | ~400 lines | ~400 lines |
| + Budget + travel + preferences | ~600+ lines | ~440+ lines |

Both files are **append-mostly** — new sections are added, existing sections
are corrected but rarely deleted. The pre-answer checklist grows from 6→8+
items as new constraints are added.

## Pitfalls

- **Don't over-generalize negative claims about child's understanding.**
  "人文类不太懂" does NOT mean "doesn't like museums." Always ask for
  clarification or let the user correct, then refine.
- **Late-arrival assumption**: the traveling-parent skeleton assumes "welcome
  home" on Fri eve. If arrival is post-bedtime, this is WRONG. Correct immediately.
- **Driving assumption**: don't assume both parents drive. If only one drives,
  ALL car trips require that parent. Non-driving parent alone = walk/e-bike/taxi only.
- **Budget "ceiling" vs "occasional overrun"**: users often say "≤200" then
  later "偶尔超没关系". Record BOTH: the routine limit AND the occasional-
  overrun policy AND the absolute ceiling. Don't just keep the lowest number.
- **Reluctant relatives**: when a family member is "not willing" to interact,
  don't frame it as a problem to solve. Record the dynamic and suggest
  strategies that respect their autonomy (mom covers costs, don't push).

## Related Skills

- **k12edu-team-deployment** — initial team creation (default profile)
- **k12-family-area-survey** — neighborhood resource research
- **in-session-team-deployment** — core multi-agent deployment pipeline
- **gateway-platform-management** — WeChat/second gateway setup
