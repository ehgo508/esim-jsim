# Data Model: eSIM 설치 안내

## esims (컬럼 추가)

| 논리명 | 물리명 | 타입 | 제약 | 설명 |
|--------|--------|------|------|------|
| 설치일시 | `installed_at` | DATETIME(6) | NULL 허용 | 사용자가 설치 완료를 누른 시각 |

## 저장하지 않는 객체

```text
enum DeviceType     { IOS, ANDROID, DESKTOP }
enum InstallMethod  { IOS_UNIVERSAL_LINK, QR_CODE, ANDROID_MANUAL }

InstallGuide
- recommendedMethod: InstallMethod
- lpaString: String              "LPA:1$smdp.example.com$ABC123"
- universalLink: String
- universalLinkSupported: boolean   (iOS 17.4 이상으로 판별됐는지)
- qrPayload: String              (= lpaString)
- manual: { smdpAddress, activationCode }
- steps: Map<InstallMethod, List<String>>
- afterArrival: List<String>
- warning: String (nullable)     이미 설치된 경우 경고

esim.markInstalled(now)  → ISSUED 일 때만 INSTALLED 로. 이미 INSTALLED 이상이면 아무 일도 안 함
```
