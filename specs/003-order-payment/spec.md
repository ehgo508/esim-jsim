# Feature Specification: 주문과 결제

**Feature Branch**: `003-order-payment`

**Created**: 2026-11-20

**Status**: Draft

**Input**: User description: "로그인한 여행자가 요금제를 골라 주문하고, 토스페이먼츠 테스트 결제로 돈을 낸다. 결제가 확정되면 eSIM 발급(004)으로 넘어간다."

## Scope

**이 기능이 다루는 것**
- 요금제 1개로 주문 만들기 (결제 대기 상태)
- 토스페이먼츠 결제위젯으로 결제 요청 (프론트)
- 결제 성공 후 서버에서 금액 검증과 결제 승인(confirm)
- 결제 실패·취소 처리
- 내 주문 목록과 상세 조회

**이 기능이 다루지 않는 것 (MVP 이후)**
- 실제 결제 키(라이브 모드), 정산
- 환불 API 연동 (MVP에서는 발급 실패 시 `FULFILLMENT_FAILED`로 표시만 하고 토스 개발자센터에서 직접 수동 취소)
- 여러 요금제 한 번에 주문(장바구니), 쿠폰, 포인트
- 결제 웹훅 (MVP는 승인 API 응답만으로 처리)

## Policy Summary

| 항목 | 정책 |
|------|------|
| 주문 권한 | 로그인한 사용자만 |
| 주문 단위 | 주문 1건 = 요금제 1개 = eSIM 1개 |
| 주문 금액 | 주문 생성 시점의 요금제 가격을 주문에 복사해 저장 (이후 요금제 가격이 바뀌어도 주문 금액은 그대로) |
| 주문번호 | 외부 공개용 `orderNo` (예: `ORD-20261120-8f3k2a9d`). 토스 규칙상 6~64자, 영문·숫자·`-`·`_` |
| 결제 수단 | 토스페이먼츠 결제위젯 (테스트 키) |
| 금액 검증 | 승인 전 토스가 돌려준 `amount`와 DB 주문 금액이 다르면 승인하지 않음 |
| 중복 승인 | 이미 `PAID` 이상인 주문의 승인 요청은 결제사를 다시 부르지 않고 현재 상태를 돌려줌 |
| 결제 대기 만료 | 생성 후 30분 지나도 결제되지 않으면 결제 불가 (`ORDER-3003`) |
| 주문 조회 | 본인 주문만 조회 가능. 남의 주문 ID로 조회하면 없는 것처럼 404 |

**주문 상태**

```text
CREATED ──결제 승인 성공──▶ PAID ──eSIM 발급 성공(004)──▶ FULFILLED
   │                         │
   │                         └──eSIM 발급 실패(004)──▶ FULFILLMENT_FAILED
   └──결제 실패·취소·만료──▶ PAYMENT_FAILED
```

## User Scenarios & Testing *(mandatory)*

### User Story 1 - 주문 만들기 (Priority: P1)

여행자가 "일본 5일 3GB"에서 구매 버튼을 누르면 결제 대기 주문이 만들어진다.

**Why this priority**: 결제위젯에 넘길 주문번호와 금액이 필요하다.

**Independent Test**: 로그인 후 주문 생성 API를 호출해 `CREATED` 주문과 금액이 응답되는지 확인한다.

**Acceptance Scenarios**:

1. **Given** 로그인 상태와 판매 중 요금제, **When** 주문하면, **Then** `CREATED` 주문이 생기고 orderNo, amount, orderName이 응답된다.
2. **Given** 판매 중지 요금제, **When** 주문하면, **Then** `PLAN-2002` 에러가 난다.

---

### User Story 2 - 결제 승인 (Priority: P1)

토스 결제창에서 결제를 마치면 성공 페이지로 돌아오고, 서버가 결제를 승인해 주문이 `PAID`가 된다.

**Why this priority**: 돈이 확정되는 핵심 단계다. 승인 API를 부르지 않으면 결제가 완료되지 않는다.

**Independent Test**: 테스트 키로 실제 결제창을 띄워 결제하거나, 결제사 클라이언트를 가짜로 바꾼 통합 테스트로 확인한다.

**Acceptance Scenarios**:

1. **Given** `CREATED` 주문, **When** 올바른 paymentKey, orderNo, amount로 승인 요청하면, **Then** 토스 승인 API가 호출되고 주문이 `PAID`가 된다.
2. **Given** `CREATED` 주문(9,900원), **When** amount를 100원으로 바꿔 승인 요청하면, **Then** 토스를 부르지 않고 `ORDER-3002` 에러가 난다.
3. **Given** 이미 `PAID`인 주문, **When** 같은 승인 요청이 다시 오면, **Then** 토스를 다시 부르지 않고 현재 주문 상태를 응답한다.
4. **Given** 토스 승인 API가 실패를 응답, **When** 승인 요청하면, **Then** 주문은 `PAYMENT_FAILED`가 되고 `ORDER-3004` 에러와 토스의 실패 사유가 응답된다.

---

### User Story 3 - 결제 실패·취소 처리 (Priority: P2)

결제창에서 사용자가 취소하면 실패 페이지로 돌아오고 주문이 `PAYMENT_FAILED`가 된다.

**Why this priority**: 실패 주문이 계속 `CREATED`로 남아도 흐름은 돌아가므로 P2.

**Independent Test**: 실패 처리 API를 호출해 상태가 바뀌는지 확인한다.

**Acceptance Scenarios**:

1. **Given** `CREATED` 주문, **When** 실패 처리 요청이 오면, **Then** `PAYMENT_FAILED`가 되고 실패 코드가 저장된다.

---

### User Story 4 - 내 주문 조회 (Priority: P2)

여행자가 내 주문 목록과 상태를 본다.

**Why this priority**: 결제 후 확인용. 006 내 eSIM 화면과 연결된다.

**Independent Test**: 두 사용자가 각각 주문한 뒤 서로의 주문이 안 보이는지 확인한다.

**Acceptance Scenarios**:

1. **Given** 주문 2건, **When** 목록을 조회하면, **Then** 최신순으로 2건이 나온다.
2. **Given** 다른 사람의 주문 ID, **When** 상세를 조회하면, **Then** `ORDER-3001`(404)이 난다.

### Edge Cases

- 결제창을 띄운 사이 요금제 가격이 바뀌어도 주문에 저장된 금액으로 결제한다.
- 성공 페이지를 새로고침해 승인 요청이 두 번 와도 한 번만 승인된다 (중복 승인 정책).
- 토스 서버가 응답하지 않으면(타임아웃) 주문을 `CREATED`로 두고 `ORDER-3005`를 응답한다. 사용자는 다시 시도할 수 있다.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: 시스템은 로그인한 사용자가 판매 중 요금제로 주문을 만들 수 있게 해야 한다.
- **FR-002**: 시스템은 주문 생성 시 요금제 이름과 가격을 주문에 복사해 저장해야 한다.
- **FR-003**: 시스템은 결제 승인 전에 요청 금액과 주문 금액이 같은지 검증해야 한다.
- **FR-004**: 시스템은 토스페이먼츠 승인 API를 서버에서 호출하고, 시크릿 키는 서버에만 둬야 한다.
- **FR-005**: 시스템은 같은 주문을 두 번 승인하지 않아야 한다.
- **FR-006**: 시스템은 결제 승인 성공 후 eSIM 발급(004)을 시작해야 한다.
- **FR-007**: 시스템은 본인 주문만 조회할 수 있게 해야 한다.

### Key Entities

- **Order**: 주문. 사용자, 요금제, 주문번호, 주문명, 금액, 상태, 생성·결제 시각.
- **Payment**: 결제 기록. 주문, 토스 paymentKey, 결제 수단, 승인 금액, 승인 시각, 실패 코드·메시지.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: 테스트 카드로 주문부터 `PAID`까지 2분 안에 끝난다.
- **SC-002**: 금액 조작 요청은 100% 거절된다.
- **SC-003**: 같은 승인 요청을 10번 보내도 결제사 승인 호출은 1번이다.

## Assumptions

- 토스페이먼츠 개발자센터에서 테스트 키(클라이언트 키, 시크릿 키)를 발급받는다. 테스트 결제는 실제 돈이 나가지 않는다.
- 결제창은 프론트엔드에서 띄운다. 백엔드는 주문 생성, 승인, 실패 처리 API만 제공한다.
