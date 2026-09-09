#!/usr/bin/env python3
"""k12edu-scoped skill-board drift watchdog (P0-3 合规闭环补齐).

Runs the shared inventory_watchdog.py as a subprocess and isolates any
k12edu-team profile lines (k12-arts / k12-character / k12-chinese /
k12-language / k12-physical / k12-stem / k12edu-orchestrator).

Exit codes:
  0 = k12edu clean (no k12edu profile issues in the global report)
  1 = k12edu drift detected (report printed)
  2 = couldn't run the base watchdog

This gives the k12edu team an independent, focused monitoring lane rather
than burying its drift inside the global watchdog's 26-issue report. The
global watchdog already scans every profile from profiles.yaml, so this
wrapper reuses its output and filters to the k12edu team.

Baseline: inventory_drift_watchdog (devops/skill-board-scoping) +
shared/skill-fence.py (profiles.yaml 单一事实源).
"""
import subprocess
import sys
from pathlib import Path

HERMES = Path.home() / ".hermes"
BASE = HERMES / "profiles" / "orchestrator" / "scripts" / "inventory_watchdog.py"
K12 = (
    "k12-arts", "k12-character", "k12-chinese", "k12-language",
    "k12-physical", "k12-stem", "k12edu-orchestrator",
)


def main() -> int:
    if not BASE.exists():
        print(f"k12edu inventory watchdog: base script missing: {BASE}")
        return 2
    try:
        r = subprocess.run(
            [sys.executable, str(BASE)],
            capture_output=True, text=True, timeout=300,
        )
    except Exception as e:  # noqa: BLE001 - report and surface as code 2
        print(f"k12edu inventory watchdog: failed to run base watchdog: {e}")
        return 2
    out = (r.stdout or "") + (r.stderr or "")
    k12_lines = [ln for ln in out.splitlines() if any(p in ln for p in K12)]
    if k12_lines:
        print("k12edu skill-board drift detected:")
        for ln in k12_lines:
            print("  " + ln)
        print(
            "Fix: hermes-agent/venv/bin/python ~/.hermes/shared/skill-fence.py "
            "apply --profile <k12-profile>"
        )
        return 1
    print("k12edu skill-board drift: clean (no k12edu profile issues)")
    return 0


if __name__ == "__main__":
    sys.exit(main())
