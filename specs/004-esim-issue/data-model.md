# Data Model: eSIM 발급

## esims

논리명: **eSIM**

| 논리명 | 물리명 | 타입 | 제약 | 설명 |
|--------|--------|------|------|------|
| eSIM ID | `id` | BIGINT | PK, AUTO_INCREMENT |  |
| 사용자 ID | `user_id` | BIGINT | FK → users.id, NOT NULL | 소유자 |
| 주문 ID | `order_id` | BIGINT | FK → orders.id, NOT NULL, UNIQUE | 주문당 1개 |
| 요금제 ID | `plan_id` | BIGINT | FK → plans.id, NOT NULL |  |
| ICCID | `iccid` | VARCHAR(22) | NOT NULL, UNIQUE | eSIM 고유 번호 |
| SM-DP+ 주소 | `smdp_address` | VARCHAR(255) | NOT NULL | SM-DP+ 서버 주소 |
| 매칭 ID | `matching_id` | VARCHAR(255) | NOT NULL | 매칭 ID (민감 정보) |
| eSIM 상태 | `status` | VARCHAR(20) | NOT NULL | `ISSUED`, `INSTALLED`, `ACTIVE`, `EXPIRED` |
| 공급사 | `provider` | VARCHAR(30) | NOT NULL | `fake`, `airalo` ... |
| 공급사 주문번호 | `provider_order_id` | VARCHAR(100) | NULL 허용 | 공급사 쪽 주문 번호 |
| 발급일시 | `issued_at` | DATETIME(6) | NOT NULL |  |
| 생성일시 | `created_at` | DATETIME(6) | NOT NULL |  |
| 수정일시 | `updated_at` | DATETIME(6) | NOT NULL |  |

## esim_issue_attempts

논리명: **eSIM 발급 시도**

| 논리명 | 물리명 | 타입 | 제약 | 설명 |
|--------|--------|------|------|------|
| 발급 시도 ID | `id` | BIGINT | PK, AUTO_INCREMENT |  |
| 주문 ID | `order_id` | BIGINT | FK → orders.id, NOT NULL |  |
| 시도 번호 | `attempt_no` | INT | NOT NULL | 1, 2, 3 |
| 시도 결과 | `result` | VARCHAR(20) | NOT NULL | `STARTED`, `SUCCEEDED`, `FAILED` |
| 실패 사유 | `failure_reason` | VARCHAR(30) | NULL 허용 | `PROVIDER_ERROR`, `OUT_OF_STOCK`, `TIMEOUT` |
| 실패 상세 | `failure_detail` | VARCHAR(500) | NULL 허용 | 공급사 메시지 |
| 생성일시 | `created_at` | DATETIME(6) | NOT NULL |  |

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
