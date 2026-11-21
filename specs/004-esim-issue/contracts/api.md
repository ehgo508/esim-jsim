# API Contract: eSIM 발급

발급 자체는 결제 승인(003) 안에서 자동 실행되므로 별도 API가 없다. 사용자용 API는 재시도 하나다.

| 기능 | Method | URI | 인증 | 성공 Status |
|------|--------|-----|------|------------|
| 발급 재시도 | POST | /api/orders/{orderNo}/esim/retry | 필요 | 200 OK |

## POST /api/orders/{orderNo}/esim/retry

요청 Body 없음.

**성공**

```json
{ "success": true, "data": { "orderNo": "ORD-20261120-8f3k2a9d", "status": "FULFILLED", "esimId": 5 } }
```

**다시 실패**

```json
{
  "success": false,
  "error": { "code": "ESIM-4002", "message": "eSIM 발급에 실패했습니다. 잠시 후 다시 시도해주세요." }
}
```

## 003 결제 승인 응답의 변화

발급까지 끝난 상태를 돌려준다.

```json
{ "success": true, "data": { "orderNo": "ORD-20261120-8f3k2a9d", "status": "FULFILLED", "esimId": 5 } }
```

발급 실패 시에도 200이며 `"status": "FULFILLMENT_FAILED"`, `"esimId": null`.

## 설정

```yaml
esim:
  provider: fake          # fake | (추후) airalo
  fake:
    mode: success         # success | fail | out-of-stock | timeout
```

## Error Codes

| 코드 | HTTP | 메시지 | 언제 |
|------|------|--------|------|
| ESIM-4001 | 409 | 재시도할 수 없는 주문입니다. | `FULFILLMENT_FAILED`가 아님 |
| ESIM-4002 | 502 | eSIM 발급에 실패했습니다. 잠시 후 다시 시도해주세요. | 공급사 오류 |
| ESIM-4003 | 409 | 재시도 횟수를 넘었습니다. 고객센터로 문의해주세요. | 이미 3번 시도함 (`시도 횟수 >= 3`) |
