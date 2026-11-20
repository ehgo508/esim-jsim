# API Contract: eSIM 설치 안내

| 기능 | Method | URI | 인증 | 성공 Status |
|------|--------|-----|------|------------|
| 설치 정보 조회 | GET | /api/esims/{esimId}/install | 필요 | 200 OK |
| 설치 완료 표시 | POST | /api/esims/{esimId}/installed | 필요 | 200 OK |

## GET /api/esims/5/install

**Query**: `device` (선택) = `ios` \| `android` \| `desktop`

**Response Header**: `Cache-Control: no-store`

```json
{
  "success": true,
  "data": {
    "esimId": 5,
    "recommendedMethod": "IOS_UNIVERSAL_LINK",
    "lpaString": "LPA:1$smdp.fake.esimtravel.test$K2F8-PQ7Z-91XA",
    "universalLink": "https://esimsetup.apple.com/esim_qrcode_provisioning?carddata=LPA:1%24smdp.fake.esimtravel.test%24K2F8-PQ7Z-91XA",
    "universalLinkSupported": true,
    "qrPayload": "LPA:1$smdp.fake.esimtravel.test$K2F8-PQ7Z-91XA",
    "manual": {
      "smdpAddress": "smdp.fake.esimtravel.test",
      "activationCode": "K2F8-PQ7Z-91XA"
    },
    "steps": {
      "IOS_UNIVERSAL_LINK": ["아래 \"eSIM 설치하기\" 버튼을 누르세요.", "\"eSIM 활성화\" 화면에서 \"계속\"을 누르세요."],
      "QR_CODE": ["다른 화면에 이 QR을 띄우고 폰 카메라로 비추세요."],
      "ANDROID_MANUAL": ["설정 → 연결 → SIM 관리자 → eSIM 추가를 여세요."]
    },
    "afterArrival": [
      "모바일 데이터 회선을 여행 eSIM으로 바꾸세요.",
      "여행 eSIM의 데이터 로밍을 켜세요.",
      "원래 회선의 데이터 로밍은 꺼 두세요."
    ],
    "warning": null
  }
}
```

## POST /api/esims/5/installed

요청 Body 없음.

```json
{ "success": true, "data": { "esimId": 5, "status": "INSTALLED", "installedAt": "2026-11-20T01:15:00Z" } }
```

## 프론트엔드 동작 메모

- `recommendedMethod`에 해당하는 방법을 가장 위에 크게 보여주고, 나머지는 "다른 방법으로 설치" 아래에 접어 둔다.
- 원탭 버튼은 `<a href="{universalLink}">` 링크다. 새 창으로 열지 않는다.
- 코드 복사는 `navigator.clipboard.writeText()`.
- QR은 `qrPayload`를 JS 라이브러리로 그린다.

## Error Codes

| 코드 | HTTP | 메시지 | 언제 |
|------|------|--------|------|
| INSTALL-5001 | 404 | eSIM을 찾을 수 없습니다. | 없음 또는 남의 eSIM |
| INSTALL-5002 | 409 | 만료된 eSIM입니다. | `EXPIRED` |
