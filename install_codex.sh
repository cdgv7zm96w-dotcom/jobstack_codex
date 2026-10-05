#!/usr/bin/env bash
set -euo pipefail

UPSTREAM_REPO="${JOBSTACK_UPSTREAM_REPO:-https://github.com/cdgv7zm96w-dotcom/jobstack.git}"
PORT_HOME="${JOBSTACK_CODEX_HOME:-$HOME/.jobstack-codex}"
UPSTREAM_DIR="$PORT_HOME/upstream"
CODEX_HOME_DIR="${CODEX_HOME:-$HOME/.codex}"
SKILLS_DIR="$CODEX_HOME_DIR/skills"
STATE_DIR="${JOBSTACK_STATE_DIR:-$HOME/.jobstack}"

SKILLS=(
  auto
  strategy
  tracker
  company-research
  portfolio
  job-search
  ncs
  salary
  retro
  experience-bank
  resume
  cover-letter
  career-history
  scout-profile
  mock-interview
  review
)

skill_desc() {
  case "$1" in
    auto) echo "jobstack 자동 진입점. 현재 자료를 스캔해 취업 준비 상태를 진단하고 다음 단계로 라우팅할 때 사용." ;;
    strategy) echo "jobstack 취업 전략 수립. 목표 직무·회사군·지원 우선순위와 준비 계획을 정리할 때 사용." ;;
    tracker) echo "jobstack 지원 현황 관리. 지원 기업, 단계, 마감, 후속 액션을 추적할 때 사용." ;;
    company-research) echo "jobstack 기업 분석. 채용공고·기업·직무를 조사하고 기업 맞춤 키워드와 지원 포인트를 만들 때 사용." ;;
    portfolio) echo "jobstack 포트폴리오 검토. 지원 직무 기준으로 프로젝트 구성과 표현을 점검할 때 사용." ;;
    job-search) echo "jobstack 채용공고 탐색. 희망 직무와 조건에 맞는 채용공고를 찾고 매칭도를 분석할 때 사용." ;;
    ncs) echo "jobstack NCS 준비. 공기업·공공기관 지원을 위한 NCS 역량과 전형 대비를 정리할 때 사용." ;;
    salary) echo "jobstack 연봉 분석. 시장 연봉 수준과 협상 포인트를 준비할 때 사용." ;;
    retro) echo "jobstack 취업 회고. 지원·면접 결과를 복기하고 다음 지원에 반영할 개선점을 정리할 때 사용." ;;
    experience-bank) echo "jobstack 경험 은행. 자소서와 면접에 재사용할 경험을 구조화해 저장·정리할 때 사용." ;;
    resume) echo "jobstack 이력서 작성·첨삭. 채용공고와 직무에 맞춰 이력서를 구성하고 개선할 때 사용." ;;
    cover-letter) echo "jobstack 자기소개서 작성·첨삭. 기업·직무 분석과 사용자 경험을 연결해 자소서를 만들 때 사용." ;;
    career-history) echo "jobstack 경력 이력 정리. 프로젝트와 경력을 사실 기반으로 구조화할 때 사용." ;;
    scout-profile) echo "jobstack 스카우트 프로필 작성. 채용 플랫폼용 프로필과 경력 소개를 다듬을 때 사용." ;;
    mock-interview) echo "jobstack 모의면접. 지원서와 공고를 바탕으로 실제 면접처럼 질문·피드백을 진행할 때 사용." ;;
    review) echo "jobstack 통합 서류 리뷰. 이력서·자소서·포트폴리오를 채용담당자 관점에서 종합 검토할 때 사용." ;;
    *) echo "jobstack Codex compatibility skill" ;;
  esac
}

require() {
  command -v "$1" >/dev/null 2>&1 || { echo "ERROR: '$1' 명령이 필요합니다." >&2; exit 1; }
}

require git
require python3

mkdir -p "$PORT_HOME" "$SKILLS_DIR"
mkdir -p "$STATE_DIR"/{profiles,tracker,company-cache,interview-history,analytics,sessions,defense-maps,job-cache}
chmod 700 "$STATE_DIR" 2>/dev/null || true

if [ -d "$UPSTREAM_DIR/.git" ]; then
  echo "[1/5] jobstack 원본 업데이트"
  git -C "$UPSTREAM_DIR" remote set-url origin "$UPSTREAM_REPO"
  git -C "$UPSTREAM_DIR" fetch --depth=1 origin main
  git -C "$UPSTREAM_DIR" reset --hard origin/main
else
  echo "[1/5] jobstack 원본 가져오기"
  rm -rf "$UPSTREAM_DIR"
  git clone --depth=1 --branch main "$UPSTREAM_REPO" "$UPSTREAM_DIR"
fi

if [ ! -x "$UPSTREAM_DIR/bin/jobstack-preamble" ]; then
  chmod +x "$UPSTREAM_DIR/bin/"* 2>/dev/null || true
fi

resolve_skill_dir() {
  local skill="$1"
  if [ -f "$UPSTREAM_DIR/$skill/SKILL.md" ]; then
    printf '%s\n' "$UPSTREAM_DIR/$skill"
  elif [ -f "$UPSTREAM_DIR/skills/$skill/SKILL.md" ]; then
    printf '%s\n' "$UPSTREAM_DIR/skills/$skill"
  else
    return 1
  fi
}

echo "[2/5] 원본 16개 스킬 확인"
for skill in "${SKILLS[@]}"; do
  if ! resolve_skill_dir "$skill" >/dev/null; then
    echo "ERROR: 원본에서 '$skill/SKILL.md'를 찾지 못했습니다." >&2
    exit 1
  fi
done

echo "[3/5] Codex용 스킬 생성"
for skill in "${SKILLS[@]}"; do
  src_dir="$(resolve_skill_dir "$skill")"
  src_file="$src_dir/SKILL.md"
  dest_dir="$SKILLS_DIR/$skill"
  dest_file="$dest_dir/SKILL.md"
  desc="$(skill_desc "$skill")"

  rm -rf "$dest_dir"
  mkdir -p "$dest_dir"

  python3 - "$src_file" "$dest_file" "$skill" "$desc" "$src_dir" "$UPSTREAM_DIR" "$STATE_DIR" <<'PY'
from pathlib import Path
import sys

src, dest, skill, desc, src_dir, upstream_dir, state_dir = sys.argv[1:]
text = Path(src).read_text(encoding="utf-8")

# Remove upstream YAML frontmatter only. Keep the full skill body.
body = text
if text.startswith("---"):
    parts = text.split("---", 2)
    if len(parts) == 3:
        body = parts[2].lstrip("\n")

# Resolve Claude-specific path variables to stable runtime paths.
replacements = {
    "${CLAUDE_SKILL_DIR}": src_dir,
    "${CLAUDE_SESSION_ID}": "codex-cloud",
    "${CLAUDE_PLUGIN_DATA:-}": state_dir,
    "${CLAUDE_PLUGIN_DATA}": state_dir,
}
for old, new in replacements.items():
    body = body.replace(old, new)

compat = f"""# Codex compatibility layer\n\n이 스킬은 `cdgv7zm96w-dotcom/jobstack`의 **원본 `{skill}` SKILL.md 본문을 유지한 Codex용 설치본**이다. 아래 호환 규칙만 적용하고, 그 뒤의 원본 단계·가드레일·출력 규칙은 임의로 축약하거나 생략하지 않는다.\n\n## 런타임 경로\n\n- 원본 스킬 디렉토리: `{src_dir}`\n- 원본 jobstack 루트: `{upstream_dir}`\n- 상태 저장 디렉토리: `{state_dir}`\n\n## Claude → Codex 도구 치환\n\n- `Bash`: Codex의 셸/터미널 실행으로 처리한다.\n- `Read`: 파일 읽기 기능 또는 셸로 파일을 읽는다.\n- `Write` / `Edit`: Codex의 파일 편집 기능으로 처리한다.\n- `Glob` / `Grep`: Codex 파일 검색 또는 `find`/`grep`/`rg`를 사용한다.\n- `AskUserQuestion`: 별도 도구를 찾지 말고 **채팅에서 사용자에게 직접 질문**한다. 원본이 한 번에 하나의 질문을 요구하면 그대로 지킨다.\n- `WebSearch` / `WebFetch`: Codex에서 사용 가능한 웹 검색/브라우징 기능을 우선 사용하고, 필요하면 네트워크가 허용된 셸 도구를 사용한다. 인터넷 접근이 꺼져 있으면 추정하지 말고 사용자에게 Cloud 네트워크 설정이 필요하다고 알린다.\n- `Agent` / `Task`: Codex에 병렬/하위 에이전트 기능이 있으면 같은 역할로 사용한다. 없으면 **동일한 조사·검토 역할을 순차 실행**하여 결과를 합친다. 기능 자체를 생략하지 않는다.\n\n## Claude 전처리 문법\n\n원본 본문에서 `!` 뒤의 백틱 명령처럼 Claude가 자동 주입하던 프리앰블 표현은 Codex에서 문장으로 출력하지 않는다. 해당 명령이 실행 컨텍스트를 만드는 단계라면 셸에서 직접 실행하고 그 출력을 작업 컨텍스트로 사용한다.\n\n특히 스킬 시작 시 원본 프리앰블이 필요하면 다음 원칙으로 실행한다.\n\n```bash\nJOBSTACK_HOME=\"{upstream_dir}\" JOBSTACK_STATE_DIR=\"{state_dir}\" bash \"{src_dir}/scripts/preamble.sh\" \"{skill}\"\n```\n\n프리앰블 스크립트가 없는 스킬이면 해당 단계를 건너뛴다.\n\n## 기능 보존 원칙\n\n- 원본의 Phase 순서, 사실 검증, 캐시/상태 저장, 문서 작성 규칙을 유지한다.\n- Claude 전용 도구 이름이 다르다는 이유로 원본 기능을 줄이거나 간단한 일반 조언으로 대체하지 않는다.\n- 원본이 `bin/`, `scripts/`, `references/`, `agents/` 파일을 참조하면 위 jobstack 원본 루트에서 실제 파일을 읽거나 실행한다.\n- 외부 사이트 접근 실패, 선택 의존성 미설치 등 **실제 런타임 제약이 있을 때만** 해당 기능의 제한을 명시한다.\n\n---\n\n# Upstream jobstack skill body\n"""

out = "---\nname: " + skill + "\ndescription: >-\n  " + desc + "\n---\n\n" + compat + "\n\n" + body
Path(dest).write_text(out, encoding="utf-8")
PY

  # Convenience link to the untouched upstream skill resources.
  ln -s "$src_dir" "$dest_dir/upstream"
  echo "  ✓ $skill"
done

echo "[4/5] Codex/jobstack 환경 정보 기록"
cat > "$PORT_HOME/env.sh" <<EOF
export JOBSTACK_HOME="$UPSTREAM_DIR"
export JOBSTACK_STATE_DIR="$STATE_DIR"
export JOBSTACK_CODEX_HOME="$PORT_HOME"
EOF
chmod 600 "$PORT_HOME/env.sh" 2>/dev/null || true

# Make scripts executable where relevant.
chmod +x "$UPSTREAM_DIR/bin/"* 2>/dev/null || true
find "$UPSTREAM_DIR" -path '*/scripts/*.sh' -type f -exec chmod +x {} + 2>/dev/null || true

echo "[5/5] 설치 검증"
"$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/verify_codex.sh"

echo ""
echo "설치 완료. Codex에서 다음처럼 시작할 수 있습니다:"
echo "  \$auto"
echo "  \$company-research"
echo "  \$resume"
echo "  \$cover-letter"
echo "  \$review"
echo "  \$mock-interview"
