# Implementation Plan: eSIM 설치 안내

**Branch**: `005-install-guide` | **Date**: 2026-11-20 | **Spec**: [spec.md](./spec.md)

## Summary

발급된 eSIM의 활성화 코드로 기기별 설치 방법을 만들어 주는 조회 API와 설치 완료 표시 API를 만든다. DB 변경이 거의 없고, 문자열 조립과 User-Agent 판별, 권한 확인이 중심이다.

## Technical Context

**Language/Version**: Java 21

**Primary Dependencies**: Spring Boot 3.x (추가 라이브러리 없음. QR 그림은 프론트에서 `qrcode` 같은 JS 라이브러리로)

**Storage**: `esims.installed_at` 컬럼 추가

**Testing**: JUnit 5 단위 테스트(링크 조립, 기기 판별), MockMvc

## Constitution Check

| 원칙 | 확인 |
|------|------|
| II. MVP First | 네이티브 앱 내 설치 제외. 웹 원탭 링크로 대체 |
| IV. 테스트 | 링크 인코딩, 기기 판별, 남의 eSIM 차단 |
| V. 보안 | 본인만 조회, `no-store`, 활성화 코드 로그 금지 |

## Processing Flow

```text
GET /api/esims/{esimId}/install?device=(선택)
        ↓
esimRepository.findByIdAndUserId(esimId, userId)
  없음 → INSTALL-5001 (404)
        ↓
esim.status == EXPIRED → INSTALL-5002 (409)
        ↓
DeviceType device = (device 파라미터가 있으면 그것)
                    아니면 DeviceDetector.detect(User-Agent)
  "iPhone" 또는 "iPad" 포함 → IOS  (+ "OS 17_4" 같은 부분에서 버전 추출)
  "Android" 포함            → ANDROID
  그 외                     → DESKTOP
        ↓
lpa = esim.activationCode()            // LPA:1$주소$매칭ID
        ↓
InstallGuideFactory.create(esim, device, iosVersion)
  universalLink = "https://esimsetup.apple.com/esim_qrcode_provisioning?carddata="
                  + URL인코딩(lpa)
  qrPayload     = lpa
  manual        = { smdpAddress, activationCode = matchingId }
  recommended   = IOS(>=17.4) → IOS_UNIVERSAL_LINK
                  IOS(<17.4)  → QR_CODE
                  ANDROID     → ANDROID_MANUAL
                  DESKTOP     → QR_CODE
  steps         = 방법별 안내 문구
  afterArrival  = 현지 도착 후 할 일
        ↓
200 OK + Cache-Control: no-store
```

## 안내 문구 (초안)

**iPhone 원탭**
1. 아래 "eSIM 설치하기" 버튼을 누르세요.
2. "eSIM 활성화" 화면에서 "계속"을 누르세요.
3. 회선 이름을 "여행"으로 정하면 구분하기 쉬워요.
4. 기본 회선은 원래 번호 그대로 두세요.

**Android 수동 입력** (메뉴 이름은 제조사마다 조금 다름)
1. 설정 → 연결 → SIM 관리자 → eSIM 추가를 여세요.
2. "QR 코드 스캔" 화면에서 "활성화 코드 입력"을 누르세요.
3. 아래 코드를 복사해 붙여 넣으세요.

**현지 도착 후 할 일**
1. 설정에서 모바일 데이터 회선을 "여행" eSIM으로 바꾸세요.
2. "여행" eSIM의 데이터 로밍을 켜세요.
3. 원래 쓰던 회선의 데이터 로밍은 꺼 두세요 (요금 폭탄 방지).

## Key Decisions

| 결정 | 선택 | 고려한 다른 방법 |
|------|------|-----------------|
| 기기 판별 위치 | 서버(User-Agent) + 프론트 지정 허용 | 프론트만으로도 가능하지만, 서버 로직과 테스트를 연습하기 좋음 |
| QR 생성 | 프론트 | 서버에서 ZXing으로 PNG 생성도 가능. 이미지에 민감 정보가 담겨 캐시 관리가 번거로움 |
| 안내 문구 위치 | 서버 응답에 포함 | 프론트에 하드코딩해도 됨. 나중에 앱과 문구를 공유하려고 서버에 둠 |
| 설치 여부 확인 | 사용자 자가 표시 | 공급사 API의 설치 상태 조회는 006에서 보정 |

## Project Structure

```text
backend/src/main/java/com/esimtravel/install/
├── controller/InstallController.java
├── service/InstallGuideService.java
├── support/DeviceDetector.java, DeviceType.java, InstallGuideFactory.java, InstallMethod.java
└── dto/InstallGuideResponse.java
```
