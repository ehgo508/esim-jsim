---
description: "내 eSIM 상태와 사용량 조회 작업 목록"
---

# Tasks: 내 eSIM 상태와 사용량 조회

**Input**: `specs/006-my-esim-usage/` 문서 전체. **선행**: 004 (Esim), 005 (`INSTALLED`)

## Phase 1: User Story 1 - 내 eSIM 목록 (P1) 🎯

- [ ] T001 [US1] `MyEsimSummaryResponse` DTO 작성 (ICCID는 뒤 4자리만)
- [ ] T002 [US1] 목록 조회 쿼리 작성 (요금제·국가를 함께 가져와 N+1 방지, 상태 그룹 정렬)
- [ ] T003 [US1] `GET /api/esims` 구현
- [ ] T004 [US1] 통합 테스트: 성공 1 (내 것만, 정렬 순서) / 실패 1 (로그인 없이 401)

## Phase 2: User Story 2 - 사용량 보기 (P1)

- [ ] T005 [US2] `EsimUsage` record 작성, `EsimProvider.getUsage()` 추가
- [ ] T006 [US2] `FakeEsimProvider.getUsage()` 구현 (발급 후 경과 시간에 따라 사용량 증가, 요금제에 통화가 있으면 통화 값 포함)
- [ ] T007 [US2] `EsimUsageSnapshot` Entity와 Repository 작성, `esims`에 `activated_at`, `expires_at` 추가
- [ ] T008 [US2] `esim.syncStatus()` 구현과 단위 테스트 (상태가 뒤로 가지 않음)
- [ ] T009 [US2] `UsageResponse.of()` 계산 로직과 단위 테스트: remaining 음수 방지, `daysLeft` 올림, 통화·문자 null
- [ ] T010 [US2] `UsageSyncService`와 `GET /api/esims/{esimId}/usage` 구현 (우선 매번 공급사 호출)
- [ ] T011 [US2] 통합 테스트: 성공 3 (데이터 전용, 통화 포함, 개통 전) / 실패 3 (남의 eSIM `USAGE-6001`, 없는 eSIM `USAGE-6001`, 로그인 없이 401). 공급사 장애 `USAGE-6002`는 T015에서

## Phase 3: User Story 3 - 갱신 주기와 장애 대응 (P2)

- [ ] T012 [US3] `Clock` Bean 등록, 서비스에서 `Instant.now(clock)` 사용
- [ ] T013 [US3] 5분 규칙 구현
- [ ] T014 [US3] 공급사 실패 시 스냅샷으로 응답(`stale = true`), 스냅샷 없으면 `USAGE-6002`
- [ ] T015 [US3] 통합 테스트 (고정 `Clock`, 공급사 `@MockitoBean`): 1분 뒤 재조회는 호출 0번, 6분 뒤는 1번, 장애 시 stale, 장애인데 저장 값이 없으면 `USAGE-6002`, 만료 eSIM은 호출 안 함

## Phase 4: 전체 흐름 확인

- [ ] T016 프론트 "내 eSIM" 화면: 목록, 사용량 막대, 마지막 갱신 시각, 설치 화면으로 가는 버튼
- [ ] T017 처음부터 끝까지 직접 해보기: 가입 → 로그인 → 일본 요금제 → 테스트 결제 → eSIM 발급 → 설치 안내 → 설치 완료 → 사용량 확인
- [ ] T018 PR을 올려 스스로 점검한 뒤 `develop`에 합치기. 전체 흐름이 확인되면 `develop`을 `main`에 합치고 MVP 완료 회고
