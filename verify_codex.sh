#!/usr/bin/env bash
set -euo pipefail

PORT_HOME="${JOBSTACK_CODEX_HOME:-$HOME/.jobstack-codex}"
UPSTREAM_DIR="$PORT_HOME/upstream"
CODEX_HOME_DIR="${CODEX_HOME:-$HOME/.codex}"
SKILLS_DIR="$CODEX_HOME_DIR/skills"
STATE_DIR="${JOBSTACK_STATE_DIR:-$HOME/.jobstack}"

SKILLS=(
  auto strategy tracker company-research portfolio job-search ncs salary
  retro experience-bank resume cover-letter career-history scout-profile
  mock-interview review
)

fail=0

echo "jobstack Codex 설치 확인"
echo "- upstream: $UPSTREAM_DIR"
echo "- skills:   $SKILLS_DIR"
echo "- state:    $STATE_DIR"
echo ""

if [ ! -d "$UPSTREAM_DIR/.git" ]; then
  echo "✗ upstream jobstack 저장소가 없습니다."
  fail=1
else
  echo "✓ upstream jobstack 저장소"
fi

if [ ! -x "$UPSTREAM_DIR/bin/jobstack-preamble" ]; then
  echo "✗ bin/jobstack-preamble을 찾거나 실행할 수 없습니다."
  fail=1
else
  echo "✓ jobstack preamble runtime"
fi

count=0
for skill in "${SKILLS[@]}"; do
  file="$SKILLS_DIR/$skill/SKILL.md"
  if [ ! -f "$file" ]; then
    echo "✗ $skill"
    fail=1
    continue
  fi
  if grep -q '\${CLAUDE_SKILL_DIR}' "$file"; then
    echo "✗ $skill — CLAUDE_SKILL_DIR 미치환"
    fail=1
    continue
  fi
  echo "✓ $skill"
  count=$((count + 1))
done

echo ""
echo "설치된 jobstack 스킬: $count / ${#SKILLS[@]}"

if command -v python3 >/dev/null 2>&1; then
  echo "✓ Python: $(python3 --version 2>&1)"
else
  echo "! Python3 없음 — 일부 문서/검색 보조 기능 제한"
fi

if command -v node >/dev/null 2>&1; then
  NODE_MAJOR="$(node -p 'process.versions.node.split(".")[0]' 2>/dev/null || echo 0)"
  if [ "${NODE_MAJOR:-0}" -ge 22 ] 2>/dev/null; then
    echo "✓ Node: $(node --version)"
  else
    echo "! Node $(node --version 2>/dev/null || true) — job-search의 일부 수집 기능은 Node 22+ 권장"
  fi
else
  echo "! Node 없음 — job-search의 일부 수집 기능 제한"
fi

if command -v pandoc >/dev/null 2>&1; then
  echo "✓ pandoc 설치됨"
else
  echo "! pandoc 없음 — 문서 내보내기 기능만 제한될 수 있음"
fi

if [ "$fail" -ne 0 ]; then
  echo ""
  echo "검증 실패. install_codex.sh를 다시 실행하세요." >&2
  exit 1
fi

echo ""
echo "핵심 16개 스킬 설치 구조 검증 통과."
