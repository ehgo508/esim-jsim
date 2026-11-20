# API Contract: 내 eSIM 상태와 사용량 조회

| 기능 | Method | URI | 인증 | 성공 Status |
|------|--------|-----|------|------------|
| 내 eSIM 목록 | GET | /api/esims | 필요 | 200 OK |
| eSIM 사용량 | GET | /api/esims/{esimId}/usage | 필요 | 200 OK |

## GET /api/esims

```json
{
  "success": true,
  "data": [
    {
      "esimId": 5,
      "planName": "일본 5일 3GB",
      "country": { "code": "JP", "name": "일본", "flag": "🇯🇵" },
      "status": "ACTIVE",
      "iccidLast4": "4821",
      "issuedAt": "2026-11-20T01:10:05Z",
      "expiresAt": "2026-11-27T03:00:00Z"
    }
  ]
}
```

## GET /api/esims/5/usage

**데이터 전용 요금제**

```json
{
  "success": true,
  "data": {
    "esimId": 5,
    "status": "ACTIVE",
    "data": { "totalMb": 3072, "usedMb": 1228, "remainingMb": 1844, "unlimited": false },
    "voice": null,
    "sms": null,
    "activatedAt": "2026-11-22T03:00:00Z",
    "expiresAt": "2026-11-27T03:00:00Z",
    "daysLeft": 4,
    "syncedAt": "2026-11-23T09:12:00Z",
    "stale": false,
    "notice": null
  }
}
```

**통화·문자 포함 요금제** (해당 부분만)

```json
"voice": { "totalMin": 100, "usedMin": 30, "remainingMin": 70 },
"sms":   { "total": 50, "used": 4, "remaining": 46 }
```

**개통 전**

```json
"data": { "totalMb": 3072, "usedMb": 0, "remainingMb": 3072, "unlimited": false },
"activatedAt": null, "expiresAt": null, "daysLeft": null,
"notice": "현지에서 처음 연결하면 사용 기간이 시작돼요."
```

## Error Codes

| 코드 | HTTP | 메시지 | 언제 |
|------|------|--------|------|
| USAGE-6001 | 404 | eSIM을 찾을 수 없습니다. | 없음 또는 남의 eSIM |
| USAGE-6002 | 503 | 사용량을 불러오지 못했습니다. 잠시 후 다시 시도해주세요. | 공급사 장애 + 저장 값 없음 |
