# jobstack_codex — Codex instructions

이 저장소는 `cdgv7zm96w-dotcom/jobstack` 원본의 16개 취업 스킬을 Codex Cloud에서 사용하기 위한 호환 레이어다.

## 시작 시

- `$HOME/.codex/skills/auto/SKILL.md`가 없으면 저장소 루트에서 `bash install_codex.sh`를 실행한다.
- 설치가 완료되면 사용자의 요청에 맞는 jobstack 스킬을 우선 사용한다.
- 사용자가 무엇부터 해야 할지 모르겠다고 하면 `auto` 스킬을 진입점으로 사용한다.

## 원본 기능 보존

- 설치된 스킬의 `Codex compatibility layer` 다음에는 upstream jobstack의 원본 SKILL 본문이 들어 있다.
- 원본의 단계, 질문 순서, 가드레일, 웹 조사 규칙, 상태 저장 규칙을 임의로 축약하지 않는다.
- Claude 전용 도구 이름만 Codex 기능으로 치환한다.
- 원본이 참조하는 `bin/`, `scripts/`, `references/`, `agents/`는 `$HOME/.jobstack-codex/upstream` 아래의 실제 파일을 사용한다.

## 도구 호환

- AskUserQuestion → 채팅에서 사용자에게 직접 질문
- Bash → 셸
- Read/Write/Edit → Codex 파일 읽기·편집
- Glob/Grep → Codex 검색 또는 find/grep/rg
- WebSearch/WebFetch → 사용 가능한 웹 검색/브라우징 또는 허용된 네트워크 셸
- Agent/Task → 병렬/하위 에이전트가 있으면 사용, 없으면 같은 역할을 순차 실행

## 상태

jobstack 상태는 기본적으로 `$HOME/.jobstack`을 사용한다. 사용자가 제공하지 않은 개인정보·경력·성과·수치를 추정해 상태에 저장하지 않는다.

## 주요 스킬

- auto: 전체 진입점
- strategy: 취업 전략
- company-research: 기업/직무 분석
- job-search: 채용공고 탐색
- resume: 이력서
- cover-letter: 자기소개서
- career-history: 경력 이력
- portfolio: 포트폴리오
- salary: 연봉 분석
- ncs: 공공기관/NCS
- review: 통합 서류 심사
- mock-interview: 모의면접
- tracker: 지원 현황
- retro: 회고
- experience-bank: 경험 정리
- scout-profile: 스카우트 프로필
