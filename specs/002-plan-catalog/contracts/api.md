# API Contract: 국가별 요금제 조회

| 기능 | Method | URI | 인증 | 성공 Status |
|------|--------|-----|------|------------|
| 국가 목록 | GET | /api/countries | 불필요 | 200 OK |
| 국가별 요금제 목록 | GET | /api/countries/{countryCode}/plans | 불필요 | 200 OK |
| 요금제 상세 | GET | /api/plans/{planId} | 불필요 | 200 OK |

## GET /api/countries

```json
{
  "success": true,
  "data": [
    { "code": "JP", "name": "일본", "flag": "🇯🇵" },
    { "code": "US", "name": "미국", "flag": "🇺🇸" }
  ]
}
```

## GET /api/countries/JP/plans

```json
{
  "success": true,
  "data": [
    { "id": 10, "name": "일본 3일 1GB", "dataMb": 1024, "unlimited": false, "validityDays": 3, "priceKrw": 4900, "voiceIncluded": false, "smsIncluded": false },
    { "id": 11, "name": "일본 5일 3GB", "dataMb": 3072, "unlimited": false, "validityDays": 5, "priceKrw": 9900, "voiceIncluded": false, "smsIncluded": false }
  ]
}
```

## GET /api/plans/11

```json
{
  "success": true,
  "data": {
    "id": 11,
    "country": { "code": "JP", "name": "일본" },
    "name": "일본 5일 3GB",
    "dataMb": 3072,
    "unlimited": false,
    "validityDays": 5,
    "priceKrw": 9900,
    "voiceMinutes": null,
    "smsCount": null,
    "notice": "현지에서 처음 연결된 시점부터 5일간 사용할 수 있습니다."
  }
}
```

## DTO

| DTO | 필드 | 비고 |
|-----|------|------|
| CountryResponse | code, name, flag | `from(Country)` |
| PlanSummaryResponse | id, name, dataMb, unlimited, validityDays, priceKrw, voiceIncluded, smsIncluded | `voiceIncluded = voiceMinutes != null` |
| PlanDetailResponse | 위 + country, voiceMinutes, smsCount, notice | `providerPackageCode`는 넣지 않음 |

## Error Codes

| 코드 | HTTP | 메시지 | 언제 |
|------|------|--------|------|
| PLAN-2001 | 404 | 판매하지 않는 국가입니다. | 국가 코드 없음 |
| PLAN-2002 | 404 | 판매 중인 요금제가 아닙니다. | 요금제 없음 또는 `STOPPED` |
