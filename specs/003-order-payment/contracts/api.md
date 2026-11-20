# API Contract: 주문과 결제

| 기능 | Method | URI | 인증 | 성공 Status |
|------|--------|-----|------|------------|
| 주문 생성 | POST | /api/orders | 필요 | 201 Created |
| 결제 승인 | POST | /api/payments/confirm | 필요 | 200 OK |
| 결제 실패 기록 | POST | /api/payments/fail | 필요 | 200 OK |
| 내 주문 목록 | GET | /api/orders | 필요 | 200 OK |
| 주문 상세 | GET | /api/orders/{orderNo} | 필요 | 200 OK |

## POST /api/orders

```json
{ "planId": 11 }
```

```json
{
  "success": true,
  "data": { "orderNo": "ORD-20261120-8f3k2a9d", "orderName": "일본 5일 3GB", "amount": 9900, "status": "CREATED" }
}
```

## POST /api/payments/confirm

프론트의 successUrl 페이지가 쿼리 파라미터를 그대로 담아 호출한다.

```json
{ "paymentKey": "tgen_20261120...", "orderNo": "ORD-20261120-8f3k2a9d", "amount": 9900 }
```

```json
{ "success": true, "data": { "orderNo": "ORD-20261120-8f3k2a9d", "status": "PAID" } }
```

## POST /api/payments/fail

```json
{ "orderNo": "ORD-20261120-8f3k2a9d", "code": "PAY_PROCESS_CANCELED", "message": "사용자에 의해 결제가 취소되었습니다." }
```

## GET /api/orders/{orderNo}

```json
{
  "success": true,
  "data": {
    "orderNo": "ORD-20261120-8f3k2a9d",
    "orderName": "일본 5일 3GB",
    "amount": 9900,
    "status": "FULFILLED",
    "paidAt": "2026-11-20T01:10:00Z",
    "esimId": 5
  }
}
```

## 외부 API: 토스페이먼츠 결제 승인 (서버 → 토스)

```text
POST https://api.tosspayments.com/v1/payments/confirm
Authorization: Basic base64("{시크릿키}:")
Content-Type: application/json

{ "paymentKey": "...", "orderId": "ORD-20261120-8f3k2a9d", "amount": 9900 }
```

성공 시 응답의 `status`가 `DONE`. 실패 시 4xx와 `{ "code": "...", "message": "..." }`. 정확한 필드는 토스페이먼츠 개발자센터 문서를 기준으로 한다.

## DTO

| DTO | 필드 | 검증 |
|-----|------|------|
| CreateOrderRequest | planId | `@NotNull` |
| CreateOrderResponse | orderNo, orderName, amount, status | |
| ConfirmPaymentRequest | paymentKey, orderNo, amount | `@NotBlank`, `@NotBlank`, `@Positive` |
| FailPaymentRequest | orderNo, code, message | `@NotBlank` (orderNo) |
| OrderResponse | orderNo, orderName, amount, status, paidAt, esimId | `esimId`는 발급 후에만 |

## Error Codes

| 코드 | HTTP | 메시지 | 언제 |
|------|------|--------|------|
| ORDER-3001 | 404 | 주문을 찾을 수 없습니다. | 없음 또는 남의 주문 |
| ORDER-3002 | 400 | 결제 금액이 주문 금액과 다릅니다. | 금액 불일치 |
| ORDER-3003 | 409 | 결제할 수 없는 주문입니다. | 만료, 실패한 주문 |
| ORDER-3004 | 402 | 결제가 승인되지 않았습니다. | 토스 승인 실패 (토스 메시지 함께) |
| ORDER-3005 | 503 | 결제사 응답이 늦습니다. 잠시 후 다시 시도해주세요. | 타임아웃 |
