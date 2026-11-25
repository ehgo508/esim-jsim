---
description: "eSIM 설치 안내 작업 목록"
---

# Tasks: eSIM 설치 안내

**Input**: `specs/005-install-guide/` 문서 전체. **선행**: 004 (Esim `ISSUED`)

## Phase 1: 순수 로직 (Spring 없이 테스트 가능)

- [ ] T001 [P] `DeviceType`, `InstallMethod` enum 작성
- [ ] T002 [P] `DeviceDetector.detect(userAgent)` 구현과 단위 테스트: iPhone, iPad, Android, Windows, null
- [ ] T003 [P] iOS 버전 추출 구현과 단위 테스트: `OS 17_4`, `OS 16_7_2`, `OS 18_0`
- [ ] T004 원탭 링크 조립 구현과 단위 테스트: `$`가 `%24`로 인코딩되는지, 접두 URL이 정확한지
- [ ] T005 `InstallGuideFactory.create()` 구현과 단위 테스트: 기기·버전별 `recommendedMethod`

## Phase 2: User Story 1, 2, 3 - 설치 정보 조회 (P1) 🎯

- [ ] T006 [US1] `InstallGuideResponse` DTO 작성
- [ ] T007 [US1] `InstallGuideService`와 `GET /api/esims/{esimId}/install` 구현 (본인 확인, 만료 확인, `Cache-Control: no-store`)
- [ ] T008 [US1] 통합 테스트: iPhone UA → `IOS_UNIVERSAL_LINK`, 구버전 iOS → `QR_CODE`
- [ ] T009 [US2] 통합 테스트: Android UA → `ANDROID_MANUAL`과 `manual` 값
- [ ] T010 [US3] 통합 테스트: PC UA → `QR_CODE`, `?device=ios`가 UA보다 우선
- [ ] T011 통합 테스트: 실패 3 (남의 eSIM `INSTALL-5001`, 만료 eSIM `INSTALL-5002`, 로그인 없이 401) + 응답 헤더 `no-store`. 성공은 T008~T010

## Phase 3: User Story 4 - 설치 완료 표시 (P2)

- [ ] T012 [US4] `esims.installed_at` 추가, `esim.markInstalled()` 구현과 단위 테스트
- [ ] T013 [US4] `POST /api/esims/{esimId}/installed` 구현
- [ ] T014 [US4] 통합 테스트: 성공 1 (`ISSUED` → `INSTALLED`) / 실패 3 (남의 eSIM `INSTALL-5001`, 없는 eSIM `INSTALL-5001`, 로그인 없이 401) + 두 번 눌러도 문제없음

## Phase 4: 프론트 연결

- [ ] T015 설치 화면 만들기: 추천 방법 크게, 원탭 버튼, 코드 복사 버튼, QR 그리기
- [ ] T016 실제 iPhone(iOS 17.4 이상)에서 원탭 버튼을 눌러 iOS 설치 화면이 열리는지 확인 (가짜 코드라 설치는 실패하는 것이 정상)

## Phase 5: Polish

- [ ] T017 로그에 활성화 코드가 없는지 확인
- [ ] T018 PR을 올려 스스로 점검한 뒤 `develop`에 합치기. 기능이 안정되면 `develop`을 `main`에 합치기
