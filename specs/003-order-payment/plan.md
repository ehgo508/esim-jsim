# Implementation Plan: 주문과 결제

**Branch**: `003-order-payment` | **Date**: 2026-11-20 | **Spec**: [spec.md](./spec.md)

## Summary

주문 생성, 토스페이먼츠 결제 승인, 실패 처리, 주문 조회를 만든다. 외부 API 호출, 트랜잭션, 상태 관리, 중복 요청 방어를 처음 다루는 가장 중요한 기능이다.

## Technical Context

**Language/Version**: Java 21

**Primary Dependencies**: Spring Boot 3.x, Spring Data JPA, `RestClient`(Spring 6.1+)로 토스 API 호출

**Storage**: MySQL 8 (`orders`, `payments`)

**Testing**: JUnit 5, MockMvc, 토스 클라이언트는 `@MockitoBean`으로 가짜 처리

**External API**: 토스페이먼츠 결제 승인 `POST https://api.tosspayments.com/v1/payments/confirm` (Basic 인증: 시크릿 키 + `:` 를 Base64 인코딩)

**Constraints**: 시크릿 키는 환경 변수 `TOSS_SECRET_KEY`. 프론트에는 클라이언트 키만 노출

## Constitution Check

| 원칙 | 확인 |
|------|------|
| II. MVP First | 환불 API, 웹훅, 장바구니 제외 |
| III. 외부 시스템 분리 | `PaymentGateway` 인터페이스 + `TossPaymentGateway` 구현. 금액은 우리 DB 기준으로 재검증 |
| IV. 테스트 | 금액 조작, 중복 승인, 결제사 실패를 테스트로 증명 |
| V. 보안 | 시크릿 키 서버 전용, 남의 주문 조회 차단 |

## Processing Flow

### 전체 결제 흐름 (프론트 + 백엔드 + 토스)

```text
[프론트] 요금제 상세에서 "구매" 클릭
        ↓
[백엔드] POST /api/orders { planId }
        → Order(CREATED, amount = plan.price) 저장
        → { orderNo, orderName, amount } 응답
        ↓
[프론트] 토스 결제위젯 렌더링 (클라이언트 키)
        → requestPayment({ orderId: orderNo, orderName, amount,
                           successUrl, failUrl })
        ↓
[토스] 결제창에서 테스트 카드로 결제
        ↓ 성공                                  ↓ 실패·취소
[프론트] successUrl?paymentKey&orderId&amount   failUrl?code&message&orderId
        ↓                                       ↓
[백엔드] POST /api/payments/confirm             POST /api/payments/fail
```

### 결제 승인 (백엔드)

```text
POST /api/payments/confirm { paymentKey, orderNo, amount }
        ↓
orderRepository.findByOrderNoAndUserId(orderNo, userId)
  없음 → ORDER-3001 (404)
        ↓
order.status 가 PAID / FULFILLED / FULFILLMENT_FAILED ?
  예 → 결제사 호출 없이 현재 상태 응답 (중복 승인 방어)
        ↓
order.status != CREATED → ORDER-3003
생성 후 30분 초과 → ORDER-3003
        ↓
amount != order.amount → ORDER-3002 (400)   ← 토스 호출 전에 막는다
        ↓
paymentGateway.confirm(paymentKey, orderNo, amount)
  ├ 성공(status=DONE) → Payment 저장, order.markPaid()
  ├ 실패 응답       → Payment(실패 코드) 저장, order.markPaymentFailed()
  │                   → ORDER-3004
  └ 타임아웃        → 상태 유지, ORDER-3005
        ↓ (트랜잭션 커밋 후)
esimIssueService.issue(orderId)    ← 004에서 연결. 003 단계에서는 PAID까지
        ↓
200 OK { orderNo, status }
```

### 동시 승인 요청 방어

같은 주문의 승인 요청 2개가 동시에 들어와 둘 다 "CREATED"를 읽으면 결제사를 두 번 부를 수 있다. 막는 방법은 두 가지다.

1. 주문 조회 시 비관적 락 (`@Lock(PESSIMISTIC_WRITE)`) → 두 번째 요청은 첫 번째가 끝날 때까지 기다린 뒤 `PAID`를 읽음. **MVP는 이 방법.**
2. `payments.order_id`에 UNIQUE 제약 → 두 번째 저장이 실패. 보조 장치로 함께 둔다.

토스도 같은 paymentKey 중복 승인을 거절하므로 돈이 두 번 나가지는 않지만, 우리 DB 상태가 꼬이지 않게 하는 것이 목적이다.

## Key Decisions

| 결정 | 선택 | 고려한 다른 방법 |
|------|------|-----------------|
| HTTP 클라이언트 | `RestClient` | `RestTemplate`(구식), `WebClient`(리액티브라 초보자에게 어려움) |
| 결제사 추상화 | `PaymentGateway` 인터페이스 | 토스 직접 호출은 테스트에서 가짜로 바꾸기 어려움 |
| 승인과 발급 | 승인 트랜잭션 커밋 후 발급 호출 | 같은 트랜잭션이면 발급 실패 시 결제 기록까지 롤백되어 "돈은 나갔는데 기록이 없음" |
| 주문번호 | 별도 `orderNo` | DB id를 그대로 쓰면 다른 주문 번호를 추측하기 쉬움 |

## Project Structure

```text
backend/src/main/java/com/esimtravel/order/
├── controller/OrderController.java, PaymentController.java
├── service/OrderService.java, PaymentService.java
├── domain/Order.java, OrderStatus.java, Payment.java
├── repository/OrderRepository.java, PaymentRepository.java
├── dto/...
└── gateway/PaymentGateway.java, TossPaymentGateway.java, PaymentConfirmResult.java
```
