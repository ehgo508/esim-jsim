# Data Model: eSIM 발급

## esims

| 컬럼 | 타입 | 제약 | 설명 |
|------|------|------|------|
| id | BIGINT | PK | |
| user_id | BIGINT | FK → users.id, NOT NULL | 소유자 |
| order_id | BIGINT | FK → orders.id, NOT NULL, UNIQUE | 주문당 1개 |
| plan_id | BIGINT | FK → plans.id, NOT NULL | |
| iccid | VARCHAR(22) | NOT NULL, UNIQUE | eSIM 고유 번호 |
| smdp_address | VARCHAR(255) | NOT NULL | SM-DP+ 서버 주소 |
| matching_id | VARCHAR(255) | NOT NULL | 매칭 ID (민감 정보) |
| status | VARCHAR(20) | NOT NULL | `ISSUED`, `INSTALLED`, `ACTIVE`, `EXPIRED` |
| provider | VARCHAR(30) | NOT NULL | `fake`, `airalo` ... |
| provider_order_id | VARCHAR(100) | | 공급사 쪽 주문 번호 |
| issued_at | DATETIME(6) | NOT NULL | |
| created_at, updated_at | DATETIME(6) | NOT NULL | |

## esim_issue_attempts

| 컬럼 | 타입 | 제약 | 설명 |
|------|------|------|------|
| id | BIGINT | PK | |
| order_id | BIGINT | FK → orders.id, NOT NULL | |
| attempt_no | INT | NOT NULL | 1, 2, 3 |
| result | VARCHAR(20) | NOT NULL | `STARTED`, `SUCCEEDED`, `FAILED` |
| failure_reason | VARCHAR(30) | | `PROVIDER_ERROR`, `OUT_OF_STOCK`, `TIMEOUT` |
| failure_detail | VARCHAR(500) | | 공급사 메시지 |
| created_at | DATETIME(6) | NOT NULL | |

UNIQUE: `(order_id, attempt_no)`

## 인터페이스

```text
interface EsimProvider
  ProvisionedEsim order(String packageCode, String reference)   // 004
  EsimUsage getUsage(String iccid)                              // 006에서 추가

record ProvisionedEsim(iccid, smdpAddress, matchingId, providerOrderId)

Esim.issue(user, order, plan, provisionedEsim, providerName) → status = ISSUED
esim.activationCode() → "LPA:1$" + smdpAddress + "$" + matchingId
```
