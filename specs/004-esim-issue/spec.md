# Feature Specification: eSIM 발급

**Feature Branch**: `004-esim-issue`

**Created**: 2026-11-20

**Status**: Draft

**Input**: User description: "결제가 끝나면 eSIM 공급사에 주문을 넣어 eSIM(활성화 코드)을 받아오고, 사용자 계정에 연결한다. 개발 중에는 가짜 공급사를 쓴다."

## Scope

**이 기능이 다루는 것**
- 결제 완료(`PAID`) 주문에 대해 공급사에 eSIM 주문하기
- 공급사가 준 eSIM 정보(ICCID, SM-DP+ 주소, 매칭 ID) 저장
- 발급 성공·실패에 따라 주문 상태 바꾸기
- 발급 실패 주문 재시도
- 공급사 인터페이스(`EsimProvider`)와 가짜 구현(`FakeEsimProvider`)

**이 기능이 다루지 않는 것 (MVP 이후)**
- 실제 공급사(Airalo, eSIM Access 등) 연동 구현. 인터페이스만 맞춰 두고 계약 후 구현체 추가
- 공급사 웹훅 수신, 비동기 발급
- 발급 실패 시 자동 환불
- 데이터 충전(top-up)

## 용어

| 용어 | 뜻 |
|------|-----|
| eSIM 프로파일 | 통신사 가입 정보 묶음. 폰 안의 eSIM 칩에 내려받아 설치한다 |
| ICCID | eSIM 프로파일의 고유 번호 (19~20자리 숫자). 공급사 API에서 eSIM을 가리키는 키 |
| SM-DP+ | 프로파일을 보관하고 폰에 내려주는 통신사 쪽 서버. 주소 예: `smdp.example.com` |
| 매칭 ID (Matching ID) | SM-DP+에서 "어느 프로파일을 줄지" 찾는 1회용 코드 |
| 활성화 코드 (LPA 문자열) | `LPA:1$<SM-DP+ 주소>$<매칭 ID>` 형식. QR 코드 안에 들어 있는 바로 그 글자 |
| 공급사 (Provider) | 여러 나라 통신사의 eSIM을 도매로 파는 회사. API로 주문하면 활성화 코드를 준다 |

## Policy Summary

| 항목 | 정책 |
|------|------|
| 발급 시점 | 결제 승인 성공 직후 자동으로 1회 시도 |
| 발급 단위 | 주문 1건당 eSIM 1개. 같은 주문으로 두 번 발급하지 않음 |
| 공급사 선택 | 설정값 `esim.provider`로 구현체 선택. 기본값 `fake` |
| 공급사 요청 식별 | 우리 `orderNo`를 공급사 요청의 참조 값으로 보냄 (중복 주문 방지, 추적용) |
| 성공 시 | Esim 저장(`ISSUED`), 주문 `FULFILLED` |
| 실패 시 | 주문 `FULFILLMENT_FAILED`, 실패 사유 저장. 결제는 그대로 (환불은 수동) |
| 재시도 | `FULFILLMENT_FAILED` 주문만, 본인이 요청. 최대 3회 |
| 활성화 코드 보호 | 본인만 조회. 로그에는 ICCID 뒤 4자리만 |

**eSIM 상태**

```text
ISSUED (발급됨, 설치 전) ──▶ INSTALLED (설치됨) ──▶ ACTIVE (사용 중) ──▶ EXPIRED (만료)
```

004에서는 `ISSUED`까지만 만든다. 이후 상태는 006에서 공급사 조회 결과로 갱신한다.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - 결제 후 자동 발급 (Priority: P1)

결제가 승인되면 사용자가 아무것도 하지 않아도 eSIM이 발급되어 계정에 들어온다.

**Why this priority**: "구매하면 바로 받는다"가 서비스의 핵심 약속이다.

**Independent Test**: 가짜 공급사로 결제 승인까지 진행한 뒤 Esim이 생기고 주문이 `FULFILLED`인지 확인한다.

**Acceptance Scenarios**:

1. **Given** `PAID` 주문, **When** 발급이 실행되면, **Then** 공급사에 요금제의 `providerPackageCode`로 주문이 들어가고 Esim(`ISSUED`)이 저장되며 주문이 `FULFILLED`가 된다.
2. **Given** 이미 Esim이 있는 주문, **When** 발급이 다시 실행되면, **Then** 공급사를 부르지 않고 기존 Esim을 그대로 둔다.

---

### User Story 2 - 발급 실패 처리와 재시도 (Priority: P1)

공급사 오류로 발급이 실패하면 사용자에게 알리고, 사용자가 다시 시도할 수 있다.

**Why this priority**: 돈을 냈는데 아무것도 안 생기는 상황이 가장 나쁜 경험이다.

**Independent Test**: 가짜 공급사를 "실패 모드"로 바꿔 실패를 만들고, 다시 "성공 모드"로 바꿔 재시도한다.

**Acceptance Scenarios**:

1. **Given** 공급사가 오류를 응답, **When** 발급이 실행되면, **Then** 주문이 `FULFILLMENT_FAILED`가 되고 실패 사유와 시도 횟수가 저장된다. 결제 기록은 그대로다.
2. **Given** `FULFILLMENT_FAILED` 주문, **When** 사용자가 재시도하면, **Then** 발급이 다시 실행되고 성공하면 `FULFILLED`가 된다.
3. **Given** 3회 실패한 주문, **When** 재시도하면, **Then** `ESIM-4003` 에러가 난다.

---

### User Story 3 - 공급사 교체 가능 (Priority: P2)

개발자가 설정 한 줄을 바꾸면 가짜 공급사에서 실제 공급사로 바뀐다.

**Why this priority**: 실제 판매 전까지는 가짜로 충분하다. 구조만 잡아 둔다.

**Independent Test**: `esim.provider=fake`일 때 `FakeEsimProvider`가 주입되는지 확인한다.

**Acceptance Scenarios**:

1. **Given** `esim.provider=fake`, **When** 서버가 뜨면, **Then** 서비스 코드는 `EsimProvider` 인터페이스만 알고 `FakeEsimProvider`가 동작한다.

### Edge Cases

- 공급사 주문은 성공했는데 우리 DB 저장이 실패하면 eSIM이 붕 뜬다. 공급사 요청에 `orderNo`를 참조 값으로 보내 두면 나중에 공급사에서 찾아 복구할 수 있다.
- 공급사 응답이 타임아웃이면 성공했는지 실패했는지 모른다. `FULFILLMENT_FAILED`로 두되 실패 사유를 `TIMEOUT`으로 구분하고, 재시도 전에 공급사에 해당 `orderNo` 주문이 있는지 먼저 조회한다 (실제 공급사 연동 시).
- 공급사에 해당 상품 재고가 없으면 재시도해도 실패한다. 실패 사유 `OUT_OF_STOCK`으로 구분한다.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: 시스템은 결제 승인 직후 eSIM 발급을 자동으로 시작해야 한다.
- **FR-002**: 시스템은 공급사 호출을 `EsimProvider` 인터페이스로만 해야 한다.
- **FR-003**: 시스템은 발급된 eSIM의 ICCID, SM-DP+ 주소, 매칭 ID를 저장하고 사용자와 주문에 연결해야 한다.
- **FR-004**: 시스템은 한 주문에 eSIM을 한 개만 발급해야 한다.
- **FR-005**: 시스템은 발급 실패 시 주문 상태와 실패 사유를 기록하고, 결제 기록은 유지해야 한다.
- **FR-006**: 사용자는 발급 실패 주문을 최대 3회까지 재시도할 수 있어야 한다.
- **FR-007**: 시스템은 활성화 코드 전체를 로그에 남기면 안 된다.

### Key Entities

- **Esim**: 발급된 eSIM. 사용자, 주문, 요금제, ICCID, SM-DP+ 주소, 매칭 ID, 상태, 공급사 이름, 공급사 주문 참조.
- **EsimIssueAttempt**: 발급 시도 기록. 주문, 시도 번호, 결과, 실패 사유, 시각.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: 결제 승인 후 10초 안에 eSIM이 계정에 나타난다 (가짜 공급사 기준).
- **SC-002**: 같은 주문에 eSIM이 2개 생기는 경우가 없다.
- **SC-003**: 발급 실패 주문은 100% `FULFILLMENT_FAILED`로 보이고 재시도 버튼이 동작한다.

## Assumptions

- MVP는 가짜 공급사만 구현한다. 실제 공급사 후보는 Airalo Partner API(샌드박스 제공), eSIM Access(최소 주문량 없음)이며, 계약은 팀이 따로 결정한다.
- 실제 공급사 API도 대체로 "상품 코드로 주문 → ICCID와 활성화 코드 응답" 구조라서 인터페이스가 맞을 것으로 가정한다. 연동 시 공급사 문서로 다시 확인한다.
