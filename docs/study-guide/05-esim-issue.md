# 4장. eSIM 발급 (004)

## 1. 이 기능에서 배우는 것

eSIM이 실제로 무엇인지(도메인 지식), 그리고 "아직 계약하지 않은 외부 회사"에 의존하는 기능을 인터페이스와 가짜 구현으로 먼저 만드는 방법. 실패를 기록하고 다시 시도하는 구조도 처음 만든다.

## 2. 알아야 할 개념

### eSIM 도메인

| 개념 | 설명 | 왜 필요한가 |
|------|------|------------|
| SIM과 eSIM | SIM은 통신사 가입 정보가 든 칩. eSIM은 폰에 내장된 칩(eUICC)에 가입 정보(프로파일)를 내려받는 방식 | 물리적으로 끼우는 과정이 없어진다 |
| 프로파일 | 통신사 가입 정보 묶음. eSIM 하나에 여러 프로파일을 넣고 골라 쓸 수 있다 | 원래 번호와 여행용을 함께 유지 |
| SM-DP+ | 프로파일을 만들어 보관하다가 폰에 안전하게 내려주는 서버. 통신사나 그 협력사가 운영 | 활성화 코드 안의 서버 주소 |
| LPA | 폰 안에서 프로파일 다운로드와 관리를 담당하는 프로그램. iOS·Android에 내장 | "LPA 문자열"이라는 이름의 유래 |
| 활성화 코드 | `LPA:1$<SM-DP+ 주소>$<매칭 ID>` 형식. QR 코드의 내용물 | 발급의 결과물이자 설치의 입력 |
| ICCID | 프로파일의 고유 번호 | 공급사 API에서 eSIM을 가리키는 키 |
| GSMA SGP.22 | 소비자용 eSIM의 국제 표준 문서 | 위 용어들이 정의된 곳 |
| 공급사 (리셀러 API) | 여러 나라 통신사 eSIM을 도매로 받아 API로 파는 회사 | 우리는 통신사가 아니므로 공급사를 통해 발급 |

### 발급 흐름 전체 그림

```text
우리 서버 ──주문 API──▶ 공급사 ──▶ 현지 통신사의 SM-DP+에 프로파일 준비
우리 서버 ◀─ICCID, 활성화 코드── 공급사
사용자 폰 ──활성화 코드로 접속──▶ SM-DP+ ──프로파일 다운로드──▶ 폰의 eSIM 칩
```

### 설계 개념

| 개념 | 설명 | 왜 필요한가 |
|------|------|------------|
| 인터페이스 | "무엇을 할 수 있는지"만 정의. 구현은 따로 | `EsimProvider` |
| 다형성과 DI | 같은 인터페이스의 구현체를 설정으로 바꿔 끼운다 | 가짜 ↔ 실제 공급사 |
| `@ConditionalOnProperty` | 설정 값에 따라 Bean을 등록할지 결정 | `esim.provider=fake` |
| 의존성 역전 (DIP) | Service가 구체 클래스가 아니라 인터페이스에 의존 | Service 코드를 안 고치고 공급사 교체 |
| record | 값만 담는 불변 클래스 (Java 16+) | `ProvisionedEsim` |
| 트랜잭션 경계 | 어디서 트랜잭션을 시작하고 끝낼지 | 공급사 호출을 트랜잭션 밖에 두기 |
| `TransactionTemplate` 또는 Service 분리 | 한 메서드 안에서 트랜잭션을 두 번 나누는 방법 | "기록 → 외부 호출 → 저장" 구조 |
| 보상과 재시도 | 실패한 작업을 기록해 두고 나중에 다시 시도하거나 되돌리는 것 | `FULFILLMENT_FAILED`, 재시도 API |
| 민감 정보 로깅 | 로그에 남기면 안 되는 값을 가리는 것(마스킹) | 활성화 코드, 매칭 ID |

## 3. 공부할 문서

| 주제 | 문서 |
|------|------|
| eSIM 개요 | GSMA eSIM 소개 https://www.gsma.com/solutions-and-impact/technologies/esim/ |
| eSIM 표준 | GSMA SGP.22 (RSP Technical Specification). 전체를 읽을 필요는 없고 용어 정의와 활성화 코드 형식 부분만 |
| 공급사 API 예시 | Airalo Partner API 문서 https://developers.partners.airalo.com/ (주문, eSIM 조회, 사용량, 설치 안내 엔드포인트 구성을 훑어보기) |
| 다른 공급사 | eSIM Access https://esimaccess.com (최소 주문량 없음), eSIM Go https://docs.esim-go.com (최소 충전 1,000달러) |
| 조건부 Bean | Spring Boot Reference의 "Condition Annotations" https://docs.spring.io/spring-boot/reference/features/developing-auto-configuration.html |
| 프로그래밍 방식 트랜잭션 | Spring Framework Reference의 "Programmatic Transaction Management" |

검색 키워드: `eSIM SM-DP+ LPA 설명`, `eSIM 활성화 코드 형식`, `스프링 인터페이스 구현체 여러 개 주입`, `@ConditionalOnProperty matchIfMissing`, `TransactionTemplate 사용법`, `외부 API 호출 트랜잭션 분리`

읽기 과제: Airalo 문서에서 "주문 요청에 무엇을 보내고 응답으로 무엇을 받는지"를 찾아 우리 `EsimProvider.order()`의 입력·출력과 비교해 본다. 빠진 것이 있으면 인터페이스를 어떻게 바꿀지 적어 본다.

## 4. 구현 순서와 힌트

| 작업 | 힌트 |
|------|------|
| T001 인터페이스 | 메서드 시그니처에 특정 공급사의 용어가 들어가지 않게 한다. "어느 공급사든 줄 수 있는 값"만 |
| T002 FakeEsimProvider | ICCID는 89로 시작하는 숫자열이다. 무작위로 만들되 중복되지 않게 한다. 실패 모드는 테스트에서 바꿀 수 있어야 한다 |
| T006 issue() | 가장 어려운 작업이다. 한 메서드에 `@Transactional`을 붙이면 공급사 호출까지 트랜잭션 안에 들어간다. 트랜잭션을 둘로 나누는 방법을 먼저 정한다 |
| T007 결제와 연결 | "결제 트랜잭션이 커밋된 뒤"에 발급이 실행되어야 한다. `PaymentService.confirm()` 밖에서(Controller나 상위 서비스) 순서대로 부르는 것이 가장 단순하다 |
| T008 중복 방지 테스트 | `issue()`를 두 번 부르고 `esimRepository.count()`가 1인지 본다 |
| T010 재시도 | 시도 횟수는 `esim_issue_attempts`를 세면 된다. 남의 주문인지 확인하는 로직은 003에서 만든 것을 재사용한다 |
| T012 의존 확인 | `EsimIssueService` 파일의 import에 `fake`가 있으면 구조가 잘못된 것이다 |
| T014 로그 | 로그용 문자열을 만드는 메서드를 Entity에 하나 두면(`maskedIccid()`) 실수할 일이 줄어든다 |

## 5. 스스로 점검할 질문

- QR 코드를 스캔하면 폰은 무엇을 하는가? SM-DP+와 매칭 ID의 역할을 넣어 설명해 보라.
- 우리 서비스가 직접 통신사가 되지 않고 공급사를 쓰는 이유는?
- `EsimIssueService`가 `FakeEsimProvider`를 직접 `new` 하면 무엇이 불편해지는가?
- 공급사 호출을 DB 트랜잭션 안에 넣으면 어떤 문제가 생기는가?
- 공급사 주문은 성공했는데 우리 DB 저장이 실패했다. 이 eSIM은 어디에 있고, 어떻게 찾을 수 있는가?
- 타임아웃은 "실패"인가? 재시도하면 어떤 위험이 있는가?
- 발급이 실패했는데 결제 승인 API가 200을 응답하는 이유는?
- 활성화 코드가 로그 파일에 남으면 무엇이 위험한가?

## 6. 흔한 실수

- 가짜 구현에 업무 규칙(중복 확인, 상태 변경)을 넣는다. 가짜는 공급사 흉내만 낸다.
- 실패 기록을 저장하는 코드가 실패한 트랜잭션과 함께 롤백되어 기록이 남지 않는다.
- 재시도 API에 본인 확인을 빠뜨린다.
- 인터페이스를 실제 공급사 하나의 API 모양에 그대로 맞춘다. 공급사를 바꿀 때 전부 고쳐야 한다.
