---
name: k12edu-custom-learning-apps
description: "Build offline learning apps for the k12edu child."
version: 1.0.0
platforms: [macos, linux]
metadata:
  hermes:
    tags: [k12edu, education, web-app, offline, child-profile, interactive, gamification]
    related_skills: [k12edu-context-profile-enrichment, k12edu-team-deployment]
---

# K12edu Custom Learning Apps

Build **custom interactive web learning apps** for the k12edu child
(your-child, 5.5yo, space-obsessed, egg/dairy allergy, sensory-integration
student). These apps complement the teacher team's advice with hands-on
practice the child can drive themselves on an iPad.

Use when: a parent asks for an app "like 斑马AI学 / 瓜瓜龙 / 洪恩" for
the child, or wants to turn screen time into active learning, or the
teacher team recommends drills that benefit from interactive practice.

> **Why custom, not off-the-shelf?** The child has a specific interest
> profile (space/astronomy), specific developmental needs (sensory-input
> processing, cognitive-flexibility training), and the family has a hard
> security constraint (code must not leave the domain). A self-hosted,
> zero-dependency, offline app honors all three; a SaaS app violates the
> security constraint and can't be themed to the child's interests.

## Core Design Principles

### 1. Zero-dependency, offline-first, code-stays-in-domain

The family's security rule is absolute: **code and data must not leave
the domain**. This rules out:
- ❌ Any cloud-hosted LLM/quiz service
- ❌ Any CDN-loaded framework (React/Vue from unpkg)
- ❌ Any analytics or telemetry
- ❌ Any backend that sends child data anywhere

What's allowed:
- ✅ Pure HTML/CSS/JS, single-file or small file set
- ✅ Browser-native APIs (Web Speech, WebAudio, LocalStorage, Canvas)
- ✅ Emoji + CSS/SVG for graphics (no image assets to license/host)
- ✅ Served from a local `python3 -m http.server` on the family Mac,
  accessed from the iPad over LAN

### 2. Child-profile-driven content

READ `child-profile.md` before designing content. The profile lives at
`~/.hermes/profiles/k12edu-orchestrator/references/child-profile.md`
(shared across both gateways). It tells you:

| Signal in profile | App design response |
|-------------------|---------------------|
| Interest in space/astronomy | Theme everything as planets/rockets/stars |
| Egg/dairy allergy | Never use food (ice cream/cake) as rewards or vocab examples |
| Sensory-input processing weak (8.9 reflection) | Multi-modal interaction (tap + voice + visual), not passive video |
| Cognitive flexibility weak (8.9 reflection) | Vary the activity within a lesson; "same toy, three ways" |
| Numberblocks fan; "6=3×2" insight | Number-decomposition games, not rote counting |
| Age 5.5, no formal English yet | Start with 5 concrete nouns per lesson, not sentences |

If the profile flags anxiety around rules, avoid timed/pressure
mechanics. If it says the child is "淘气赖皮", build generous reward
loops — stars on every correct answer, not just at the end.

### 3. The 4-stage lesson loop (斑马AI学 pattern)

Every lesson is 4 stages, each ~2-3 minutes for a 5.5yo attention span:

```
Stage 1: 听看 (Learn)   — present new material, auto-play audio
Stage 2: 点说 (Speak)   — child taps each item to hear + repeat
Stage 3: 配对 (Match)   — multiple-choice, word↔meaning or word↔image
Stage 4: 挑战 (Quiz)    — listen/look and choose, scored
   → Complete screen with stars earned + next-lesson link
```

This loop is the same for every subject; only the content changes. A
`render()` function switches stages; `go(n)` advances.

### 4. Reward + feedback mechanics

- **Stars**: +1 for learn steps, +2 for correct match/quiz answers.
  Persisted in `localStorage` so they survive reloads.
- **Audio FX**: WebAudio-synthesized tones for correct/wrong/celebrate
  (no audio files). `AudioFX.correct()` = ascending arpeggio; `.wrong()`
  = low sawtooth; `.celebrate()` = 4-note fanfare.
- **Visual feedback**: green border + check on correct; red border +
  shake animation on wrong; star-pop particle on reward.
- **Never punitive**: wrong answers shake + "再想想～", never a buzzer
  or "wrong" text. The child retries; the stage doesn't advance on wrong.

### 5. Voice via Web Speech API (no audio files)

```js
Speaker.speakEn('Sun');     // en-US, rate 0.75, pitch 1.2 (kid-friendly)
Speaker.speakZh('三个星球'); // zh-CN, rate 1.0
```
Caveat: voice quality/availability depends on the device. iPad Safari
has good en-US/zh-CN voices; test on the target device. If a voice is
missing, the app still works (text + visual), just silent — acceptable
fallback, not a blocker.

### 6. Touch-first, iPad-friendly

- `user-scalable=no` + large tap targets (min 44px)
- `:active { transform: scale(0.95) }` haptic-feel on tap
- Grid layouts collapse to 1-column on narrow screens
- No hover-dependent interactions (iPad has no hover)
- Audio context unlocked on first user click (browser autoplay policy)

## Tech Stack (concrete)

| Concern | Choice | Why |
|---------|--------|-----|
| Markup | Plain HTML5 | No build step, opens by double-click |
| Styling | Plain CSS3 (flexbox/grid, animations) | No preprocessor |
| Logic | Vanilla JS (ES6, no framework) | No npm, no bundle |
| Graphics | Emoji + CSS gradients | Zero image assets |
| Voice | Web Speech API (`speechSynthesis`) | Browser-native, no files |
| Sound FX | WebAudio API (`OscillatorNode`) | Synthesized, no files |
| Progress | `localStorage` | Persists across sessions, no backend |
| Serving | `python3 -m http.server` | Already installed, LAN-accessible |

Total app weight for 2 full lessons + home: ~48KB. Loads instantly.

## File Layout

```
k12-app/
├── index.html              # Home: subject cards + progress
├── css/style.css           # Shared styles (dark space theme)
├── js/common.js            # StarManager, Progress, Speaker, AudioFX, feedback
├── english/lesson1.html    # One file per lesson
├── math/lesson1.html
└── README.md               # How to run (3 methods)
```

Each lesson file is self-contained (inline `<script>`), imports
`common.js` for the shared utilities. Adding a lesson = one new file
+ one card on `index.html`.

## Verification Protocol

Before declaring an app "done", verify with REAL tool calls:

1. **Serve + curl**: `python3 -m http.server <port>` then
   `curl -sS -o /dev/null -w "%{http_code}"` each file. All must be 200.
2. **Browser render**: `browser_navigate` to the home page; check the
   snapshot shows the subject cards.
3. **Interaction test**: `browser_navigate` into a lesson, then
   `browser_console` to read `document.querySelector('.big-emoji').textContent`
   — confirm it equals the expected first item. Click "next" via
   `browser_click`, re-read, confirm the item advanced.
4. **JS syntax**: if Node is available, `node -c js/common.js`.

Do NOT declare success based on write_file's `verified:true` alone.
The session that produced this skill hit a stale-cache/worktree trap
where `write_file` reported success but the served file was an older
copy — only the browser interaction test caught it. See Pitfalls.

## Pitfalls

### write_file "verified:true" but served file is stale

Observed 2026-08: `write_file` to `english/lesson1.html` returned
`verified: true` and the diff showed the new content, but the file
actually served by `http.server` (and read back via `grep`) was an
older version with different class names (`word-intro-grid` vs the
new `big-card`). Root cause was a stale worktree/symlink layer
intercepting the write path while the serve path read the real file.

**Mitigation**: after writing, ALWAYS re-read via an independent channel
(`grep -c "<new class>" file` or `browser_console` reading the rendered
DOM) before trusting the write. If they disagree, delete the file
(`rm`), re-write, re-verify. The `_warning: file was modified since you
last read it` field on write_file's return is the tell — treat it as a
signal to re-read, not noise.

### Inferring parent identity from message content

When building these apps, the request often comes through dad
(orchestrator/weixin main gateway) even though the app is for the child
both parents raise. The app's content may draw on mom's observation
notes (forwarded by dad). Archive content under the author (mom); address
the build request to the reader (dad). See the `weixin-multi-account-delivery`
skill (default profile) for the two-gateway identity table. Do NOT call
dad "妈妈" in your replies.

### Guessing family-member name mappings

When a parent sends a list of names (cousins, aunts), DO NOT infer the
mapping to existing profile entries by age/order alone. Observed
2026-08: the agent guessed "悠悠 is the 姑姑大儿子 who brought the prize
toy cars" and was wrong — it was 童童 (the younger cousin). Always mark
inferred mappings as `⚠️待确认` and ask the parent to confirm in the
next turn. Record confirmed mappings immediately and remove the
uncertainty marker.

### Food as reward/example

The child has egg + dairy allergies. Never use ice cream, cake, cheese,
milk as reward icons, correct-answer animations, or word-list items
(an English lesson must not include "Ice cream" as a vocab word without
a clear allergy-safe substitute noted). Use stars, rockets, planets,
dinosaurs — things the child loves and that are safe.

## References

- `references/app-design-rationale.md` — why each design choice maps to
  a specific child-profile signal (the "each detail = a design
  constraint" mapping, mirroring the enrichment skill's pattern). TO
  CREATE when the next lesson is built.
- `templates/lesson-template.html` — copy-and-modify starter for a new
  4-stage lesson in any subject. TO CREATE from the verified lesson1
  files when a third lesson is requested (avoid templating from a
  one-off before the pattern is proven).

## Related Skills

- **k12edu-context-profile-enrichment** (default profile) — the
  child-profile.md you READ to drive app design. Read it before every
  new lesson. Cannot be patched from orchestrator profile; recommend
  `hermes curator adopt` if enrichment rules need updating.
- **k12edu-team-deployment** (default profile) — the teacher team whose
  advice the app anchors.
