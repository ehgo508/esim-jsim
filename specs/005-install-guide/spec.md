# Feature Specification: eSIM 설치 안내

**Feature Branch**: `005-install-guide`

**Created**: 2026-11-20

**Status**: Draft

**Input**: User description: "발급받은 eSIM을 복잡한 과정 없이 폰에 설치하게 한다. iPhone은 버튼 한 번으로 설치 화면을 열고, Android는 QR과 코드 복사로 안내한다."

## Scope

**이 기능이 다루는 것**
- 내 eSIM의 설치 정보 조회 (활성화 코드, 원탭 설치 링크, QR용 문자열, 수동 입력 값)
- 접속 기기 판별 (iPhone / Android / PC)에 따른 설치 방법 추천
- 기기별 단계 안내 문구
- 설치 후 현지에서 켜야 하는 설정 안내 (데이터 로밍, 데이터 회선 선택)
- 사용자가 "설치했어요"를 누르면 설치 완료로 표시

**이 기능이 다루지 않는 것**
- 폰 설정을 서버나 웹이 직접 바꾸는 것. iOS와 Android 모두 일반 웹·앱에 허용하지 않는다 (아래 "플랫폼 제약" 참고)
- 네이티브 앱에서의 앱 내 설치 (MVP 이후, 통신사 권한 필요)
- 기기 모델별 eSIM 지원 여부 자동 판정 (안내 문구로 대체)

## 플랫폼 제약 (조사 결과)

| 플랫폼 | 할 수 있는 것 | 할 수 없는 것 |
|--------|--------------|--------------|
| iPhone (iOS 17.4 이상) | 웹 링크 `https://esimsetup.apple.com/esim_qrcode_provisioning?carddata=<활성화 코드>`를 누르면 시스템의 eSIM 설치 화면이 바로 열린다. QR 스캔 불필요 | 사용자 확인 없이 자동 설치, 회선 전환, 로밍 켜기 |
| iPhone (iOS 17.4 미만) | QR 스캔 또는 설정에서 수동 입력 | 원탭 링크 |
| Android | 설정에서 QR 스캔 또는 활성화 코드 수동 입력. 화면의 QR 이미지를 길게 눌러 추가하는 기능은 제조사·버전마다 다름 | 일반 앱·웹에서 직접 설치 (시스템 권한 또는 통신사 권한 필요) |
| PC | QR을 화면에 띄워 폰 카메라로 스캔 | |

그래서 이 서비스의 "복잡한 과정 생략"은 다음을 뜻한다: 이메일로 QR을 받아 다른 기기에 띄울 필요 없이, 구매한 그 폰에서 버튼 한 번(iPhone) 또는 복사 한 번(Android)으로 설치 화면까지 간다.

## Policy Summary

| 항목 | 정책 |
|------|------|
| 조회 권한 | eSIM 소유자 본인만. 남의 eSIM은 404 |
| 조회 가능 상태 | `ISSUED`, `INSTALLED`, `ACTIVE`. `EXPIRED`는 설치 정보를 주지 않음 |
| 기기 판별 | 요청 헤더 `User-Agent`로 서버가 추천 방법을 계산. 프론트가 `?device=`로 직접 지정할 수도 있음 |
| 추천 방법 | iPhone·iPad → `IOS_UNIVERSAL_LINK`, Android → `ANDROID_MANUAL`, 그 외 → `QR_CODE` |
| iOS 버전 | User-Agent의 iOS 버전이 17.4 미만이면 `QR_CODE`와 수동 입력을 추천 |
| 원탭 링크 | 활성화 코드를 URL 인코딩해 `carddata`에 넣음. 링크는 소문자 유지 |
| QR 코드 | 서버는 QR에 담을 문자열(활성화 코드)만 주고, 그림은 프론트가 그림 |
| 응답 캐시 | 설치 정보 응답은 `Cache-Control: no-store` |
| 설치 완료 표시 | 사용자가 직접 누름. `ISSUED` → `INSTALLED`. 실제 설치 여부는 006에서 공급사 조회로 보정 |

## User Scenarios & Testing *(mandatory)*

### User Story 1 - iPhone에서 원탭 설치 (Priority: P1)

iPhone으로 구매한 여행자가 "eSIM 설치하기" 버튼을 누르면 iOS의 eSIM 추가 화면이 바로 열린다.

**Why this priority**: 이 프로젝트가 풀려는 문제의 핵심이다.

**Independent Test**: iPhone User-Agent로 설치 정보 API를 호출해 `recommendedMethod`와 링크 형식을 확인한다. 실제 공급사 eSIM이 생기면 실기기에서 링크를 눌러 본다.

**Acceptance Scenarios**:

1. **Given** `ISSUED` eSIM과 iOS 17.4 이상 User-Agent, **When** 설치 정보를 조회하면, **Then** `recommendedMethod = IOS_UNIVERSAL_LINK`이고 `universalLink`가 `https://esimsetup.apple.com/esim_qrcode_provisioning?carddata=`로 시작한다.
2. **Given** iOS 16 User-Agent, **When** 조회하면, **Then** `recommendedMethod = QR_CODE`이고 원탭 링크는 "iOS 17.4 이상에서 사용 가능" 안내와 함께 제공된다.

---

### User Story 2 - Android에서 코드로 설치 (Priority: P1)

Android로 구매한 여행자가 SM-DP+ 주소와 활성화 코드를 복사해 설정에 붙여 넣는다.

**Why this priority**: 사용자의 절반 가까이가 Android다.

**Independent Test**: Android User-Agent로 조회해 수동 입력 값과 단계 안내가 오는지 확인한다.

**Acceptance Scenarios**:

1. **Given** Android User-Agent, **When** 조회하면, **Then** `recommendedMethod = ANDROID_MANUAL`이고 `manual.smdpAddress`, `manual.activationCode`, 전체 `lpaString`, 단계 안내가 응답된다.

---

### User Story 3 - PC에서 QR로 설치 (Priority: P2)

PC로 구매한 여행자가 화면의 QR을 폰 카메라로 찍는다.

**Why this priority**: 기존 서비스와 같은 방식이라 차별점은 아니지만 빠지면 PC 구매자가 막힌다.

**Independent Test**: PC User-Agent로 조회해 `qrPayload`가 활성화 코드와 같은지 확인한다.

**Acceptance Scenarios**:

1. **Given** PC User-Agent, **When** 조회하면, **Then** `recommendedMethod = QR_CODE`이고 `qrPayload`가 `LPA:1$...` 문자열이다.

---

### User Story 4 - 현지 설정 안내와 설치 완료 표시 (Priority: P2)

설치를 마친 여행자가 "설치했어요"를 누르고, 현지 도착 후 켜야 할 설정 체크리스트를 본다.

**Why this priority**: 설치는 했는데 로밍을 안 켜서 안 되는 경우가 가장 흔한 문의다.

**Independent Test**: 설치 완료 API 호출 후 상태가 `INSTALLED`로 바뀌는지 확인한다.

**Acceptance Scenarios**:

1. **Given** `ISSUED` eSIM, **When** 설치 완료를 누르면, **Then** `INSTALLED`가 된다.
2. **Given** 설치 정보 응답, **When** 확인하면, **Then** 기기별 "현지 도착 후 할 일" 목록이 들어 있다.

### Edge Cases

- 활성화 코드의 `$` 문자는 URL에 넣을 때 `%24`로 인코딩해야 한다.
- 이미 설치된 eSIM의 활성화 코드는 대부분 재사용할 수 없다. `INSTALLED` 이상이면 "이미 설치한 eSIM은 다시 설치할 수 없을 수 있어요. 삭제하지 마세요." 경고를 함께 준다.
- User-Agent가 없거나 알 수 없으면 `QR_CODE`를 추천하고 모든 방법을 함께 준다.
- iPad는 User-Agent가 Mac처럼 보일 수 있다. 프론트의 `?device=ios` 지정으로 보완한다.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: 시스템은 본인 eSIM의 활성화 코드, 원탭 링크, QR용 문자열, 수동 입력 값을 한 번에 제공해야 한다.
- **FR-002**: 시스템은 접속 기기에 맞는 설치 방법을 추천해야 한다.
- **FR-003**: 시스템은 기기별 단계 안내와 현지 설정 안내를 제공해야 한다.
- **FR-004**: 시스템은 만료된 eSIM의 설치 정보를 제공하면 안 된다.
- **FR-005**: 사용자는 설치 완료를 직접 표시할 수 있어야 한다.
- **FR-006**: 시스템은 설치 정보 응답이 브라우저나 중간 서버에 캐시되지 않게 해야 한다.

### Key Entities

- **Esim** (004에서 만든 것): `installedAt` 필드 추가.
- **InstallGuide**: DB에 저장하지 않는 응답 객체. 방법별 값과 안내 문구.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: iPhone 사용자가 결제 완료 화면에서 eSIM 설치 화면까지 탭 2번 이하로 도달한다.
- **SC-002**: Android 사용자가 다른 기기 없이 설치 화면까지 갈 수 있다.
- **SC-003**: 팀원 3명이 안내만 보고 (실제 공급사 eSIM 기준) 설치에 성공한다. 가짜 공급사 단계에서는 화면 흐름만 확인한다.

## Assumptions

- 원탭 링크는 Apple이 공개한 방식이지만 형식이 바뀔 수 있다. 링크 조립 코드를 한 곳에 모아 둔다.
- 가짜 공급사의 활성화 코드로는 실제 설치가 되지 않는다. 링크가 열리고 iOS가 "유효하지 않은 코드"로 응답하는 것까지가 MVP 확인 범위다.
