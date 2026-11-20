# 7장. 보안과 운영, 그리고 다음 단계

## 1. 의존성 보안 관리

"Java가 해킹당했다"는 뉴스의 대부분은 언어가 아니라 특정 라이브러리의 특정 버전 문제다. 2021년 Log4j(Log4Shell)와 2022년 Spring4Shell이 대표적이고, 둘 다 패치 버전으로 올리면 해결됐다. Python, JavaScript도 같은 종류의 사고가 꾸준히 난다. 지켜야 할 것은 언어 선택이 아니라 습관이다.

| 습관 | 방법 |
|------|------|
| 최신 패치 유지 | Spring Boot의 패치 버전(3.x.y의 y)을 주기적으로 올린다. Spring Boot가 관리하는 라이브러리는 버전을 직접 적지 않는다 |
| 취약점 알림 | GitHub 저장소 Settings → Security에서 Dependabot alerts를 켠다 |
| 자동 업데이트 PR | Dependabot version updates 설정 (`.github/dependabot.yml`) |
| 출처 확인 | 블로그의 낯선 라이브러리를 그대로 추가하지 않는다. 공식 저장소와 최근 업데이트 날짜를 본다 |

문서: GitHub Docs "Dependabot" https://docs.github.com/ko/code-security/dependabot , Spring 보안 권고 https://spring.io/security

## 2. 비밀 값 관리

| 값 | 두는 곳 | 두면 안 되는 곳 |
|----|--------|----------------|
| DB 비밀번호, JWT 서명 키, 토스 시크릿 키, 공급사 API 키 | 환경 변수, Git에서 제외한 `application-local.yml` | 코드, `application.yml`, 프론트엔드, 로그, 단체 채팅방 |

Git에 한 번이라도 올라간 키는 지워도 기록에 남는다. 즉시 새 키로 바꾼다.

## 3. 이 프로젝트의 보안 점검표

| 항목 | 해당 기능 |
|------|----------|
| 비밀번호는 BCrypt 해시로만 저장 | 001 |
| 로그인 실패 사유를 구분해 알려주지 않음 | 001 |
| Entity를 응답으로 직접 내보내지 않음 | 전체 |
| 결제 금액을 서버에서 검증 | 003 |
| 시크릿 키는 서버에만 | 003 |
| 내 것만 조회 (주문, eSIM) | 003, 005, 006 |
| 활성화 코드를 로그·캐시에 남기지 않음 | 004, 005 |
| 입력 검증 (`@Valid`) | 전체 |

참고: OWASP Top 10 https://owasp.org/www-project-top-ten/ 에서 "Broken Access Control"과 "Cryptographic Failures" 두 항목만 먼저 읽는다. 위 점검표가 이 둘에 해당한다.

## 4. MVP 이후에 할 수 있는 것

| 단계 | 내용 | 새로 배우는 것 |
|------|------|---------------|
| 실제 공급사 연동 | Airalo 샌드박스나 eSIM Access로 `EsimProvider` 구현체 추가. 실제 eSIM으로 원탭 설치 확인 | 외부 API 인증, 웹훅 |
| 배포 | 클라우드에 서버와 DB 올리기, HTTPS | Docker, CI/CD, 도메인 |
| 알림 | 출국 전날 설치 안내, 데이터 80% 사용 알림 | 스케줄러, 이메일·푸시 |
| 환불 | 발급 실패 시 결제 자동 취소 | 보상 트랜잭션 |
| 모바일 앱 | 웹을 감싼 앱부터 시작. 앱 내 설치는 공급사·통신사 권한 협의 필요 | iOS/Android 개발, 스토어 심사 |
| 사업 측면 | 실제 판매에는 사업자 등록과 통신 관련 신고가 필요할 수 있다 | 전문가 확인 필요. 이 문서의 범위 밖 |

## 5. 새 기능을 추가할 때 (Spec Kit)

1. Claude Code에서 `/speckit-specify 출국 전날 설치 안내 알림을 보낸다`처럼 기능을 설명한다. `specs/007-.../spec.md`가 생긴다.
2. `/speckit-clarify`로 모호한 부분에 대한 질문을 받고 답한다.
3. `/speckit-plan`으로 계획을, `/speckit-tasks`로 작업 목록을 만든다.
4. 구현은 직접 한다. `/speckit-implement`는 쓰지 않는다 (프로젝트 원칙 I).
