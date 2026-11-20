# 이심전심 (eSIM Travel) Constitution

이 문서는 프로젝트의 모든 명세(spec), 계획(plan), 작업(tasks)이 지켜야 할 원칙이다. 다른 문서와 충돌하면 이 문서가 우선한다.

## Core Principles

### I. 사람이 직접 구현한다 (NON-NEGOTIABLE)
이 프로젝트는 팀원들이 Spring을 배우면서 만드는 학습 프로젝트다.
- 구현 코드는 팀원이 직접 작성한다. `/speckit-implement`는 사용하지 않는다.
- AI 도구는 명세 작성, 설계 검토, 개념 설명, 힌트, 코드 리뷰에만 쓴다. 완성 코드를 붙여 넣지 않는다.
- `tasks.md`는 사람이 체크하며 진행하는 할 일 목록이다.

### II. 끝까지 한 번 돌아가는 것이 먼저 (MVP First)
핵심 흐름은 "가입 → 요금제 선택 → 결제 → eSIM 발급 → 폰에 설치 → 사용량 확인"이다.
- 이 흐름에 필요 없는 기능은 MVP 이후로 미룬다 (출국일 알림, 충전, 모바일 앱, 관리자 화면 등).
- 기능은 001부터 006까지 번호 순서로 만든다. 앞 기능이 다음 기능의 기반이 된다.

### III. 외부 시스템은 인터페이스 뒤에 숨긴다
eSIM 공급사(Airalo 등)와 결제사(토스페이먼츠)는 바뀔 수 있고, 학습 중에는 실제 돈을 쓰지 않는다.
- eSIM 공급사는 `EsimProvider` 인터페이스로 감싸고, 개발 중에는 가짜 구현(`FakeEsimProvider`)을 쓴다.
- 결제는 토스페이먼츠 테스트 키만 사용한다. 실제 결제 키는 MVP 범위 밖이다.
- 외부 응답은 그대로 믿지 않고 우리 서버에서 다시 검증한다 (금액, 상태 등).

### IV. 테스트로 동작을 증명한다
- 각 API는 성공 1개 이상, 실패 1개 이상의 테스트를 가진다.
- 서비스 로직은 단위 테스트, API는 `@SpringBootTest` + MockMvc 통합 테스트로 확인한다.
- 테스트가 통과하지 않은 기능은 완료로 보지 않는다.

### V. 보안과 개인정보는 기본값이다
- 비밀번호는 BCrypt로 단방향 해시한다. 원문을 저장하거나 로그에 남기지 않는다.
- eSIM 활성화 코드(LPA 문자열)는 돈과 같다. 본인만 조회할 수 있고, 로그에 전체를 남기지 않는다.
- API 키, 시크릿, DB 비밀번호는 코드와 Git에 넣지 않는다. 환경 변수나 `application-local.yml`(Git 제외)로 관리한다.
- 의존성은 최신 패치 버전을 유지하고 GitHub Dependabot 알림을 켠다.

## Technology Stack

| 영역 | 선택 | 이유 |
|------|------|------|
| 언어 | Java 21 | 팀원 모두 Java 문법을 앎. LTS 버전 |
| 프레임워크 | Spring Boot 3.x | 국내 자료가 많고, 참고 문서(WeaveWay)와 같은 스택 |
| 빌드 | Gradle | Spring Initializr 기본값 |
| DB | MySQL 8 (로컬은 Docker), 테스트는 H2 | 가장 흔한 조합 |
| ORM | Spring Data JPA | 테이블을 자바 객체로 다룸 |
| 인증 | Spring Security + JWT (Access Token) | 웹과 나중의 앱이 같은 API를 씀 |
| 결제 | 토스페이먼츠 결제위젯 (테스트 모드) | 국내 결제, 테스트 키 무료 |
| eSIM 공급 | `EsimProvider` 인터페이스 + 가짜 구현 | 실제 공급사 계약 전에도 개발 가능 |
| 프론트엔드 | [NEEDS CLARIFICATION: 팀에 프론트 담당이 있으면 React, 없으면 Thymeleaf 또는 순수 HTML/JS] | 백엔드는 REST API로 만들어 어느 쪽이든 붙일 수 있게 함 |
| 테스트 | JUnit 5, MockMvc, AssertJ | Spring Boot 기본 포함 |

## API Conventions

- 모든 API는 `/api/**` 아래에 둔다. JSON으로 주고받는다.
- 성공 응답: `{ "success": true, "data": { ... } }`
- 실패 응답: `{ "success": false, "error": { "code": "ORDER-3001", "message": "사용자에게 보여줄 문장" } }`
- 에러 코드는 `도메인-번호` 형식이다. USER-1xxx, PLAN-2xxx, ORDER-3xxx, ESIM-4xxx, INSTALL-5xxx, USAGE-6xxx.
- 요청 DTO와 응답 DTO는 Entity와 분리한다. Entity를 그대로 응답하지 않는다.
- 돈은 원 단위 정수(`long`)로 다룬다. `double`을 쓰지 않는다.
- 시간은 서버에서 UTC로 저장하고, 화면에서 한국 시간으로 보여준다.

## Development Workflow

- 기능마다 `specs/NNN-기능명/` 폴더의 문서를 먼저 읽고 시작한다: `spec.md`(무엇을) → `plan.md`(어떻게) → `data-model.md`, `contracts/api.md`(구체 설계) → `tasks.md`(할 일).
- 브랜치는 세 종류다.
  - `main`: 항상 돌아가는 완성본. 기능이 끝나고 테스트가 통과했을 때만 `develop`에서 합친다. 직접 커밋하지 않는다.
  - `develop`: 개발 중인 코드가 모이는 곳. 기능 브랜치를 Pull Request로 합친다.
  - 기능 브랜치: `develop`에서 딴다 (예: `001-user-account`). 팀원 1명 이상이 리뷰한 뒤 `develop`에 합친다.
- 구현 중 명세가 바뀌면 코드보다 문서를 먼저 고친다.

## Governance

- 이 헌법을 바꾸려면 팀원 과반이 동의하고, 아래 버전과 날짜를 갱신한다.
- 리뷰할 때 원칙 I~V를 지켰는지 확인한다.

**Version**: 1.1.0 | **Ratified**: 2026-11-20 | **Last Amended**: 2026-11-20
