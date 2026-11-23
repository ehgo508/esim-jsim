# Data Model: 주문과 결제

## orders

논리명: **주문**

| 논리명 | 물리명 | 타입 | 제약 | 설명 |
|--------|--------|------|------|------|
| 주문 ID | `id` | BIGINT | PK, AUTO_INCREMENT |  |
| 주문번호 | `order_no` | VARCHAR(64) | NOT NULL, UNIQUE | 외부 공개 주문번호 |
| 사용자 ID | `user_id` | BIGINT | FK → users.id, NOT NULL |  |
| 요금제 ID | `plan_id` | BIGINT | FK → plans.id, NOT NULL |  |
| 주문명 | `order_name` | VARCHAR(100) | NOT NULL | 주문 시점 요금제 이름 복사 |
| 주문 금액 | `amount_krw` | BIGINT | NOT NULL | 주문 시점 가격 복사 |
| 주문 상태 | `status` | VARCHAR(30) | NOT NULL | `CREATED`, `PAID`, `FULFILLED`, `PAYMENT_FAILED`, `FULFILLMENT_FAILED` |
| 결제일시 | `paid_at` | DATETIME(6) | NULL 허용 |  |
| 생성일시 | `created_at` | DATETIME(6) | NOT NULL |  |
| 수정일시 | `updated_at` | DATETIME(6) | NOT NULL |  |

인덱스: `(user_id, created_at DESC)`

## payments

논리명: **결제**

| 논리명 | 물리명 | 타입 | 제약 | 설명 |
|--------|--------|------|------|------|
| 결제 ID | `id` | BIGINT | PK, AUTO_INCREMENT |  |
| 주문 ID | `order_id` | BIGINT | FK → orders.id, NOT NULL, UNIQUE | 주문당 결제 1건 |
| 결제 키 | `payment_key` | VARCHAR(200) | UNIQUE, NULL 허용 | 토스 결제 키 |
| 결제 수단 | `method` | VARCHAR(30) | NULL 허용 | 카드, 간편결제 등 |
| 승인 금액 | `approved_amount_krw` | BIGINT | NULL 허용 |  |
| 결제 상태 | `status` | VARCHAR(20) | NOT NULL | `DONE`, `FAILED` |
| 실패 코드 | `fail_code` | VARCHAR(100) | NULL 허용 | 토스 실패 코드 |
| 실패 메시지 | `fail_message` | VARCHAR(500) | NULL 허용 |  |
| 승인일시 | `approved_at` | DATETIME(6) | NULL 허용 |  |
| 생성일시 | `created_at` | DATETIME(6) | NOT NULL |  |

## Entity 메서드 (상태 변경은 Entity 안에서만)

```text
Order.create(user, plan)        → status = CREATED, orderName·amount 복사, orderNo 생성
order.markPaid(paidAt)          → CREATED 일 때만 가능, 아니면 예외
order.markPaymentFailed()       → CREATED 일 때만
order.markFulfilled()           → PAID 일 때만        (004)
order.markFulfillmentFailed()   → PAID 일 때만        (004)
order.isExpired(now)            → createdAt + 30분 < now
```
