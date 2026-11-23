---
description: "국가별 요금제 조회 작업 목록"
---

# Tasks: 국가별 요금제 조회

**Input**: `specs/002-plan-catalog/` 문서 전체. **선행**: 001 Phase 2 (공통 응답·에러)

## Phase 1: Domain

- [ ] T001 `plan/domain/Country` Entity 작성
- [ ] T002 `plan/domain/Plan`, `PlanStatus` Entity 작성 (`@ManyToOne(fetch = LAZY)`로 Country 연결)
- [ ] T003 `CountryRepository`, `PlanRepository` 작성 (메서드 이름 쿼리 + 국가 목록용 `@Query`)
- [ ] T004 `@DataJpaTest`로 Repository 테스트: 판매 중지 제외, 가격순 정렬, 판매 요금제 없는 국가 제외

## Phase 2: User Story 1, 2 - 국가 목록과 국가별 요금제 (P1) 🎯

- [ ] T005 [US1] `CountryResponse`, `PlanSummaryResponse` DTO 작성
- [ ] T006 [US1] `PlanQueryService` 작성 (`@Transactional(readOnly = true)`)
- [ ] T007 [US1] `GET /api/countries` 구현
- [ ] T008 [US2] `GET /api/countries/{countryCode}/plans` 구현 (소문자 코드 허용)
- [ ] T009 [US2] `SecurityConfig`에 조회 API `permitAll` 추가
- [ ] T010 [US2] 통합 테스트: 성공 1 (정상 목록, 로그인 없이 호출 가능) / 실패 1 (없는 국가 `PLAN-2001`). 국가 목록 API는 실패할 경우가 없으므로 성공 1 (판매 중인 요금제가 있는 국가만 나옴)

## Phase 3: User Story 3 - 요금제 상세 (P2)

- [ ] T011 [US3] `PlanDetailResponse` 작성 (`providerPackageCode` 제외 확인)
- [ ] T012 [US3] `GET /api/plans/{planId}` 구현
- [ ] T013 [US3] 통합 테스트: 성공 1 (정상) / 실패 2 (판매 중지 `PLAN-2002`, 없는 ID `PLAN-2002`)

## Phase 4: 초기 데이터

- [ ] T014 `PlanDataInitializer` 작성 (`@Profile("local")`, 데이터가 비어 있을 때만 data-model.md 예시 데이터 입력)
- [ ] T015 로컬 실행 후 브라우저나 Postman으로 세 API 확인
- [ ] T015-1 [P] 프론트: `contracts/api.md` 응답을 `frontend/src/api/types.ts`에 TypeScript 타입으로 옮기기
- [ ] T015-2 프론트 "국가 목록" 화면과 "국가별 요금제" 화면 (가격순, 무제한·통화 포함 표시)
- [ ] T015-3 프론트 "요금제 상세" 화면 (구매 버튼은 003에서 연결)

## Phase 5: Polish

- [ ] T016 목록 조회 시 실행되는 SQL을 로그로 확인하고, N+1 문제(요금제마다 국가를 다시 조회)가 없는지 점검
- [ ] T017 코드 리뷰 후 PR로 `develop`에 합치기. 기능이 안정되면 `develop`을 `main`에 합치기
