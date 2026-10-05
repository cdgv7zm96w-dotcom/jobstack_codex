# jobstack_codex

`thesun4sky/jobstack`의 **16개 취업 스킬을 OpenAI Codex Cloud에서 최대한 원본 동작대로 사용하기 위한 호환 레이어**입니다.

이 저장소는 jobstack 내용을 짧게 요약해서 다시 만든 버전이 아닙니다. Codex Cloud 환경을 만들 때 원본 jobstack 포크(`cdgv7zm96w-dotcom/jobstack`)를 가져오고, 각 원본 `SKILL.md`의 본문을 유지한 채 Claude 전용 실행 표현만 Codex 방식으로 해석할 수 있도록 설치합니다.

## 목표로 하는 16개 스킬

- `$auto`
- `$strategy`
- `$tracker`
- `$company-research`
- `$portfolio`
- `$job-search`
- `$ncs`
- `$salary`
- `$retro`
- `$experience-bank`
- `$resume`
- `$cover-letter`
- `$career-history`
- `$scout-profile`
- `$mock-interview`
- `$review`

## Codex Cloud에서 설정

새 Cloud 환경의 Repository로 이 저장소를 선택한 뒤, **Setup script**에 아래 한 줄을 넣습니다.

```bash
bash install_codex.sh
```

`company-research`, `job-search`처럼 실시간 웹 접근이 필요한 기능을 쓰려면 Cloud 환경의 인터넷/네트워크 접근도 허용해 주세요.

설치가 끝나면 Codex에서 예를 들어 다음처럼 사용합니다.

```text
$auto
취업 준비 시작해줘.
```

```text
$company-research
현대엔지니어링 도시계획 경력직을 분석해줘.
```

```text
$cover-letter
이 채용공고와 내 경력을 바탕으로 자기소개서를 작성해줘.
```

```text
$review
내 이력서와 자기소개서를 최종 심사해줘.
```

## 원본 보존 방식

설치기는 다음 순서로 동작합니다.

1. `cdgv7zm96w-dotcom/jobstack`의 최신 `main`을 `$HOME/.jobstack-codex/upstream`에 가져옵니다.
2. 원본의 16개 스킬을 확인합니다.
3. 각 원본 `SKILL.md`의 **본문 전체를 유지**합니다.
4. Claude Code 전용 frontmatter/환경변수와 도구 이름을 Codex에서 해석할 수 있도록 호환 지침을 앞에 추가합니다.
5. 완성된 스킬을 `$HOME/.codex/skills/<스킬명>/SKILL.md`로 설치합니다.
6. jobstack의 기존 `bin/`, `scripts/`, `references/`, `agents/`는 원본 저장소 안에서 그대로 참조합니다.

따라서 jobstack 원본이 업데이트되면 Cloud 환경을 다시 빌드할 때 최신 원본을 다시 가져올 수 있습니다.

## 확인

설치 후 다음 명령으로 16개 스킬이 모두 설치됐는지 확인할 수 있습니다.

```bash
bash verify_codex.sh
```

## 호환성 범위

목표는 **jobstack의 16개 핵심 취업 스킬의 기능적 동등성**입니다. Claude Code에만 존재하는 `AskUserQuestion`, `Agent`, `Task`, `WebSearch`, `WebFetch` 등의 이름은 Codex의 대화/셸/웹 기능으로 치환합니다.

로컬 cron, Telegram 봇처럼 Claude/Codex 대화형 스킬 밖의 부가기능은 Codex Cloud 핵심 사용 범위와 별개입니다.

원본 프로젝트: `thesun4sky/jobstack`  
사용 중인 개인 포크: `cdgv7zm96w-dotcom/jobstack`
