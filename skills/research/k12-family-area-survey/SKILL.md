---
name: k12-family-area-survey
description: "Survey a residence's nearby family/K12 resources."
version: 1.0.0
metadata:
  hermes:
    tags: [k12, education, research, neighborhood, chinese, local-life, relocation]
    related_skills: [chinese-web-research, wechat-article-search, maps, find-nearby]
---

# K12 Family Area Survey (周边资源调研)

Produce a structured, distance-tiered report of family/K12 resources around a
named residence in a Chinese city. Validated 2026-08 on a Jinan Gaoxin
万科麓城 survey that ran 30+ queries across 12 resource dimensions.

## When to Use

- User names a residence (小区/楼盘) + city/district and asks about **周边 /
  附近 / 配套**, or "is this a good area for a family/school-age kid"
- Relocation / home-buying due-diligence for a family
- "帮我调研 XX 小区周边的教育/公园/博物馆/商场/医院/交通"
- A k12-* teacher agent needs a local-activity menu for a specific family

## The Two Hard Problems (and their fixes)

### Problem 1 — Chinese search engines almost all CAPTCHA from CN egress IPs

The full engine-status ladder and CAPTCHA signatures live in
`chinese-web-research` (sibling skill). The single most reliable rung for
**K12 / family / local-life** topics is **Sogou 微信搜索** (the
`wechat-article-search` skill script), NOT 360搜索 and NOT Baidu. WeChat is
the primary publishing channel in China for education, healthcare, local
parenting, and district policy — hit rate is highest there and it does not
CAPTCHA. See `references/chinese-search-engine-ladder.md` for the corrected
ladder and the rate-limit pitfall.

**Throttle rule**: the WeChat script silently returns empty arrays after
~25 rapid-fire queries (NOT errors). Throttle to ≤1 query per 3–5 seconds;
it recovers after a cooldown. Batch your queries, and if you see a run of
`0 results`, STOP, wait 30s+, and resume — do not rephrase, the query is
fine.

### Problem 2 — Nominatim geocoding times out from non-CN networks

The `maps` skill's `search`/`reverse` commands hit Nominatim, which often
SSL-handshake-times-out from outside China. **OSRM's public router
(`router.project-osrm.org`) is a different host and works.** When you can't
geocode a place name, look up approximate coordinates from your domain
knowledge or from the WeChat article snippets (they often name intersections,
e.g. "凤凰路与舜风路交汇处"), then use OSRM's route API for real
driving distance/time between coordinate pairs. See the OSRM pattern in
`references/chinese-search-engine-ladder.md`.

## Workflow

1. **Pin the residence precisely.** Goal: a street intersection or coordinate
   pair. Run one WeChat query `"<residence> <city> 地址"` and read the snippets
   for intersection/landmark language ("XX路与YY路交汇处", "XX以东"). This
   anchors every distance. If you get nothing, the project may be too niche
   for tokenized search — try the developer name + district instead.

2. **Confirm the school catchment (学区).** This is the #1 thing a K12 family
   cares about. Query `"<residence> 学区 小学"` and `"<residence> 招生简章"`.
   Cross-check across multiple years of official 招生简章 — catchments are
   stable when named consistently across 2–3 years. WeChat surfaces these
   reliably because schools publish them as 公众号 articles.

3. **Run a query per resource dimension.** Use this checklist (drop dims the
   user didn't ask for, add any they did):
   - 幼儿园 / kindergartens (look for 对口/幼小联合教研 mentions)
   - 小学/中学 / primary & middle schools
   - 培训机构 / tutoring (art/music/sport/English — note "双减" whitelist)
   - 图书馆/泉城书房 / libraries & reading rooms
   - 公园/遛娃 / parks & outdoor kid spaces
   - 博物馆/科技馆 / museums & science centers
   - 商场/亲子餐厅/室内游乐场 / malls, family restaurants, indoor playgrounds
   - 运动/游泳/足球/篮球 / sports facilities
   - 医院/儿童医院 / hospitals incl. children's hospital
   - 交通/通勤 / transport, esp. to any named commute destination (高铁站 etc.)
   - Distance to city landmarks / 三大名胜 equivalents

4. **Build the distance matrix.** With the residence coordinate fixed, call
   OSRM once per target to get driving km + minutes. Apply a peak-hour
   multiplier (×1.5–2) for the reported time — OSRM is free-flow.

5. **Structure the report by distance tier**, not by resource type. Families
   think "what can I walk to / ride to / drive to", not "list all parks then
   all museums". Use three tiers:
   - **Walking/电动车圈 (≤5km)** — daily high-frequency
   - **SUV圈 (5–20km)** — weekend depth (museums, major parks)
   - **远郊 (>20km)** — holiday/day-trip
   Each tier gets a table of resources with name, distance, free/paid,
   age-fit, and a one-line teacher/agent note.

6. **Add a priority cheat-sheet appendix** — "for scenario X, first choice =
   Y, second = Z". This is what the family actually opens the report for.

## Report Quality Bar

- **Every distance is real** (OSRM path), not guessed. State the source and
  the peak-hour caveat once in a methodology note.
- **Every place is ≥2-source confirmed** (official account + parenting blogger
  + news). Never list a place from a single stale listing.
- **Teacher/agent voice**: include concrete recommendations per resource
  (best age, what to avoid, combo routes). The user is often a parent who
  wants a verdict, not a directory.
- **Never fabricate** 门票/地址/电话. If a detail couldn't be confirmed, mark
  it "~" or "需现场核实" — see the anti-fabrication rule in `cognition-self-check`.

## Output Template

A copy-ready skeleton lives in `templates/area-survey-report.md`. It has the
12 sections pre-headed (location, education, parks, museums, malls, sports,
hospitals, distances, commute, walking/cycling routes, priority cheat-sheet,
methodology). Clone it and fill in.

## Pitfalls

- **Do NOT trust Nominatim/OSRM `search` for Chinese place names** — geocode
  failures are the norm, not the exception. Resolve the residence to a
  coordinate via article snippets + your own geographic knowledge, then OSRM
  the route.
- **Do NOT fire 40 WeChat queries back-to-back** — silent empty results after
  ~25. Throttle. Batch in groups of ~10 with 30s gaps.
- **Do NOT treat Bing-RSS tokenization failure as a bad query** — switch
  engines, don't rephrase.
- **Peak-hour driving time ≠ OSRM time.** Always multiply and label it.
- **School catchments change.** Cite the most recent 招生简章 year and note
  "verify before enrollment".
- **Under-construction facilities** (e.g. 儿童医院东院区, planned 少儿图书馆
  东馆) are valuable to report but MUST be labeled "在建/规划" with status —
  do not present them as open.

## Overlap Note

The corrected Chinese search-engine ladder is general (applies to any Chinese
research, not just K12 area surveys). The canonical home for it is
`chinese-web-research`, which in the original 2026-08 validation listed 360
as "✅ WORKS" — that is now IP-reputation-dependent and frequently CAPTCHAs.
If `chinese-web-research` is editable in your profile, patch its engine table
to reflect the Sogou-WeChat-first ladder (mirrored in this skill's
`references/chinese-search-engine-ladder.md`) rather than duplicating it here.
