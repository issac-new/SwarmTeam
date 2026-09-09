#!/usr/bin/env bash
# k12edu_skill_health_audit.sh — k12edu-scoped skill health audit (P0-3)
# 用途：为 k12edu 团队（7 个 profile）提供独立 skill 健康度审计车道，
#       不混入全局 skill-health-audit-weekly 的大库扫描。
# 检查项：
#   A. real-dir shared-category 副本（skill-board drift，应为 symlink）
#   B. stale skill（>90 天未更新，k12 作用域内）
#   C. broken symlink（k12 作用域内）
#   D. 重复 skill 名称（k12 作用域内）
# 原则：只报告不修改，结果供人工决策。
# 退出：0=clean，1=有 issue，2=意外错误。
set -uo pipefail

HERMES="$HOME/.hermes"
SHARED="$HERMES/skills"
DAYS_STALE="${1:-90}"
K12_PROFILES="k12-arts k12-character k12-chinese k12-language k12-physical k12-stem k12edu-orchestrator"

# k12 作用域目录：k12 相关共享技能 + 各 k12 profile 的 skills 目录
scope_dirs="$SHARED/k12-lesson-design $SHARED/k12edu"
for p in $K12_PROFILES; do
  sd="$HERMES/profiles/$p/skills"
  [ -d "$sd" ] && scope_dirs="$scope_dirs $sd"
done

issues=0
echo "================================================================"
echo "k12edu Skill 健康度审计"
echo "================================================================"
echo "审计时间: $(date '+%Y-%m-%d %H:%M:%S')"
echo "Stale 阈值: ${DAYS_STALE} 天"
echo ""

# Phase A: real-dir shared-category copies (skill-board drift)
echo "[Phase A] real-dir shared-category copies (drift)"
for p in $K12_PROFILES; do
  sd="$HERMES/profiles/$p/skills"
  [ -d "$sd" ] || continue
  for e in "$sd"/*; do
    [ -e "$e" ] || continue
    name=$(basename "$e")
    [ -L "$e" ] && continue
    if [ -d "$SHARED/$name" ]; then
      echo "  DIRCOPY $p/$name (应为 symlink -> shared/$name)"
      issues=$((issues + 1))
    fi
  done
done
echo ""

# Phase B: stale skills under k12 scope
echo "[Phase B] Stale skill (>${DAYS_STALE}d)"
stale_found=0
for d in $scope_dirs; do
  [ -d "$d" ] || continue
  while IFS= read -r f; do
    [ -n "$f" ] || continue
    mtime=$(stat -f "%Sm" -t "%Y-%m-%d" "$f" 2>/dev/null || stat -c "%y" "$f" 2>/dev/null | cut -d' ' -f1)
    rel=${f#$HERMES/}
    echo "  STALE: $rel (最后更新: $mtime)"
    issues=$((issues + 1)); stale_found=$((stale_found + 1))
  done < <(find "$d" -name "SKILL.md" -mtime +"$DAYS_STALE" 2>/dev/null)
done
[ "$stale_found" -eq 0 ] && echo "  (无)"
echo ""

# Phase C: broken symlinks in k12 scope
echo "[Phase C] Broken symlinks"
broken_found=0
for d in $scope_dirs; do
  [ -d "$d" ] || continue
  while IFS= read -r l; do
    [ -n "$l" ] || continue
    rel=${l#$HERMES/}
    echo "  BROKEN-LINK: $rel"
    issues=$((issues + 1)); broken_found=$((broken_found + 1))
  done < <(find -L "$d" -type l 2>/dev/null)
done
[ "$broken_found" -eq 0 ] && echo "  (无)"
echo ""

# Phase D: duplicate skill names in k12 scope
echo "[Phase D] Duplicate skill names"
dup_found=0
names=$(find $scope_dirs -name "SKILL.md" -exec dirname {} \; 2>/dev/null | xargs -I{} basename {} | sort | uniq -d)
if [ -n "$names" ]; then
  while IFS= read -r n; do
    [ -n "$n" ] || continue
    echo "  DUPLICATE: $n"
    issues=$((issues + 1)); dup_found=$((dup_found + 1))
  done <<< "$names"
else
  echo "  (无)"
fi
echo ""

if [ "$issues" -gt 0 ]; then
  echo "k12edu skill health: $issues issue(s) found"
  exit 1
fi
echo "k12edu skill health: clean"
exit 0
