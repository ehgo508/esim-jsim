# Data Model: 주문과 결제

## orders

| 컬럼 | 타입 | 제약 | 설명 |
|------|------|------|------|
| id | BIGINT | PK | |
| order_no | VARCHAR(64) | NOT NULL, UNIQUE | 외부 공개 주문번호 |
| user_id | BIGINT | FK → users.id, NOT NULL | |
| plan_id | BIGINT | FK → plans.id, NOT NULL | |
| order_name | VARCHAR(100) | NOT NULL | 주문 시점 요금제 이름 복사 |
| amount_krw | BIGINT | NOT NULL | 주문 시점 가격 복사 |
| status | VARCHAR(30) | NOT NULL | `CREATED`, `PAID`, `FULFILLED`, `PAYMENT_FAILED`, `FULFILLMENT_FAILED` |
| paid_at | DATETIME(6) | | |
| created_at, updated_at | DATETIME(6) | NOT NULL | |

인덱스: `(user_id, created_at DESC)`

## payments

| 컬럼 | 타입 | 제약 | 설명 |
|------|------|------|------|
| id | BIGINT | PK | |
| order_id | BIGINT | FK → orders.id, NOT NULL, UNIQUE | 주문당 결제 1건 |
| payment_key | VARCHAR(200) | UNIQUE | 토스 결제 키 |
| method | VARCHAR(30) | | 카드, 간편결제 등 |
| approved_amount_krw | BIGINT | | |
| status | VARCHAR(20) | NOT NULL | `DONE`, `FAILED` |
| fail_code | VARCHAR(100) | | 토스 실패 코드 |
| fail_message | VARCHAR(500) | | |
| approved_at | DATETIME(6) | | |
| created_at | DATETIME(6) | NOT NULL | |

## Entity 메서드 (상태 변경은 Entity 안에서만)

```text
Order.create(user, plan)        → status = CREATED, orderName·amount 복사, orderNo 생성
order.markPaid(paidAt)          → CREATED 일 때만 가능, 아니면 예외
order.markPaymentFailed()       → CREATED 일 때만
order.markFulfilled()           → PAID 일 때만        (004)
order.markFulfillmentFailed()   → PAID 일 때만        (004)
order.isExpired(now)            → createdAt + 30분 < now
```
