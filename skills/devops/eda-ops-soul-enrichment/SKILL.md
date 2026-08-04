---
name: eda-ops-soul-enrichment
description: >-
  Enrich EDA-team and Ops-team agent SOUL.md files with `## 具体操作命令手册`
  sections. Covers the Loop-Engineering-anchor insertion technique (distinct
  from the product/collaboration team's double-`---` footer), pre-existing
  duplicate section detection, batch enrichment of 9+ files via execute_code,
  and the EDA/Ops-specific command toolchains (iverilog/verilator/yosys,
  gmsh/FEniCS/OpenFOAM/ParaView, promtool/amtool/kubectl, terraform/helm).
  Use when adding command manuals to EDA or Ops team SOUL.md files.
version: 1.0.0
platforms: [macos, linux]
metadata:
  hermes:
    tags: [soul-design, eda-team, ops-team, patch-techniques]
    related_skills:
      - soul-enrichment-command-manual
      - multi-team-soul-enrichment
      - agent-soul-patching
      - collaboration-team-soul-enrichment
---

# EDA/Ops Team SOUL.md Command Manual Enrichment

Add `## 具体操作命令手册` sections to EDA-team and Ops-team agent SOUL.md
files. These teams have a **different footer structure** than the
product/collaboration teams that `soul-enrichment-command-manual` covers,
requiring a different insertion technique.

## When to Use

- Enriching EDA team profiles: eda-ai, eda-ipcore, eda-multiphysics,
  eda-optics, eda-physics, eda-toolchain
- Enriching Ops team profiles: ops-devops, ops-incident-commander, ops-sre
- Any SOUL.md whose footer uses `## Loop Engineering 验证门` as the last
  content section before `## 隐私保护规则`

## Footer Variant: Loop Engineering Anchor

EDA/Ops SOUL.md files end with this structure (NOT the double-`---` footer
found in product/collaboration team files):

```
...content...

## Loop Engineering 验证门

`kanban_complete` 前必须通过验证门：从任务 body 提取验收条件，用工具验证（非自述）。
失败 → `kanban_comment` 记录教训 → 重试（最多3轮）→ 仍失败 → `kanban_block`。
详见 `~/.hermes/profiles/_shared/loop-engineering-gates.md`。

---

## 隐私保护规则（全局强制）
```

**Insertion point**: BEFORE `## Loop Engineering 验证门`. This is the last
"real content" section before the privacy footer.

**Technique**: Use Python `str.replace()` via `execute_code`, NOT the
`patch` tool. The anchor `## Loop Engineering 验证门` is unique per file
and Python's exact byte matching avoids all fuzzy-matching pitfalls.

```python
ANCHOR = "## Loop Engineering 验证门"
new_content = content.replace(ANCHOR, new_section.rstrip() + "\n\n" + ANCHOR, 1)
```

## Critical Pitfall: Pre-existing Duplicate Section

**Always** assert `content.count("## 具体操作命令手册") == 0` before
inserting. Some EDA/Ops SOUL.md files already have a stale
`## 具体操作命令手册` section sitting BETWEEN `## Loop Engineering 验证门`
and `## 隐私保护规则`.

If you insert a new one before the Loop Engineering anchor without
checking, you end up with TWO copies:
1. Your new section (before Loop Engineering) ✓
2. The stale section (after Loop Engineering, before privacy) ✗

The `str.replace(ANCHOR, ...)` approach does NOT detect this because it
only looks at the anchor string, not the full file content.

**Fix**: If `count > 0`, either skip (already enriched) or remove the
stale section between Loop Engineering and privacy rules before inserting.

## Batch Enrichment Pattern (9+ files)

When enriching 9+ SOUL.md files at once (e.g. EDA team 6 + Ops team 3),
do NOT issue 9 separate `patch` tool calls. Write one `execute_code`
script:

1. Define a dict `{profile_name: section_content}` with all 9 sections
2. Loop over each file:
   - Read content
   - Assert `count("## 具体操作命令手册") == 0` (no pre-existing)
   - Assert `count(ANCHOR) == 1` (anchor exists and is unique)
   - `content.replace(ANCHOR, section + "\n\n" + ANCHOR, 1)`
   - Write back
3. Post-insert assertions per file:
   - `count("## 具体操作命令手册") == 1`
   - `index("## 具体操作命令手册") < index(ANCHOR)` (correct order)
4. Print a before/after line-count table

This pattern completed 9 files in 0.05s vs 9 sequential patch round-trips.

## EDA Team Command Toolchains

| Profile | Core Tools | Sample Commands |
|---------|-----------|-----------------|
| eda-ai | PyTorch, torchvision, TensorBoard, ONNX | `python train.py --config configs/default.yaml --amp`, `tensorboard --logdir runs/` |
| eda-ipcore | iverilog, Verilator, Yosys, Chisel/sbt, GTKWave | `iverilog -g2012 rtl/fifo.v tb/tb_fifo.v`, `yosys -p "synth -top fifo"` |
| eda-multiphysics | gmsh, meshio, FEniCS, OpenFOAM, ParaView | `gmsh mesh/heat_exchanger.geo -3`, `mpirun -np 4 python solve_thermoelastic.py` |
| eda-optics | NumPy, SciPy, POPPY, RayOptics, Matplotlib | `python scripts/angular_spectrum.py --wavelength 633e-9`, POPPY PSF simulation |
| eda-physics | FEniCS/dolfin, FiPy, ParaView | `python solve_poisson.py --mesh mesh/cavity.xdmf`, FiPy diffusion |
| eda-toolchain | CMake, CTest, CPack, clang-tidy, cppcheck, lcov | `cmake -S . -B build -DCMAKE_BUILD_TYPE=Release`, `ctest --test-dir build -j$(nproc)` |

## Ops Team Command Toolchains

| Profile | Core Tools | Sample Commands |
|---------|-----------|-----------------|
| ops-devops | Terraform, Pulumi, Docker, kubectl, Helm, gitlab-ci-local | `terraform plan -var-file=envs/prod.tfvars`, `helm upgrade --install app ./charts/app` |
| ops-incident-commander | kubectl, grep, curl (Statuspage API), Python | `kubectl get events -n prod --sort-by='.lastTimestamp'`, `kubectl logs -l app=api --since=1h \| grep -iE 'error\|panic'` |
| ops-sre | promtool, amtool, curl (Grafana API), jq | `promtool query instant http://prometheus:9090 'histogram_quantile(0.99, ...)'`, `amtool silence add --duration=1h` |

## Section Content Template

Each command manual section should follow this structure:

```markdown
## 具体操作命令手册

<role-specific one-line description>. 不记得参数时回查本节而非猜测。

```bash
# <action description>
<real command with realistic parameters>

# <action description>
<real command with realistic parameters>

# ... 5-8 commands total
```

> <role-specific note about ACP delegation vs hands-on verification>
```

Key principles:
- Commands must be **real and executable** — no fabricated tool names
- Each command gets a one-line `# comment` above it
- Include environment setup (venv activation, dependency install) for
  Python-based profiles
- End with a `>` blockquote noting that coding itself is delegated to
  ACP/Claude Code; these commands are for hands-on verification

## Verification After Enrichment

```bash
for p in eda-ai eda-ipcore eda-multiphysics eda-optics eda-physics eda-toolchain \
         ops-devops ops-incident-commander ops-sre; do
  f=~/.hermes/profiles/$p/SOUL.md
  echo "===== $p ====="
  grep -n "## 具体操作命令手册\|## Loop Engineering 验证门\|## 隐私保护规则" "$f"
  echo "lines: $(wc -l < "$f")"
done
```

Verify for each file:
1. Exactly 1 occurrence of `## 具体操作命令手册`
2. Section order: `## 具体操作命令手册` → `## Loop Engineering 验证门` → `## 隐私保护规则`
3. No duplicate sections between Loop Engineering and privacy rules

## Related Skills

- **soul-enrichment-command-manual** (default) — product/collaboration team
  command manuals, double-`---` footer pattern, `patch` fuzzy-matching pitfalls
- **multi-team-soul-enrichment** (default) — three-phase pipeline for
  cross-team enrichment (catalog → enrich → verify)
- **agent-soul-patching** (default) — batch SOUL.md patching techniques,
  two-phase patch pattern, concurrency strategy
- **collaboration-team-soul-enrichment** (default) — collaboration team
  (architect/PM/coder/reviewer/tester) command manuals
- **soul-md-privacy-section-patching** (default) — two-copy privacy section
  trap and trailing-backtick orphanage issue
