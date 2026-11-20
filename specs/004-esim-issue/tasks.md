---
description: "eSIM 발급 작업 목록"
---

# Tasks: eSIM 발급

**Input**: `specs/004-esim-issue/` 문서 전체. **선행**: 003 (주문 `PAID`)

## Phase 1: 공급사 인터페이스

- [ ] T001 `EsimProvider` 인터페이스, `ProvisionedEsim` record, `EsimProviderException`, `FailureReason` 작성
- [ ] T002 `FakeEsimProvider` 구현 (`esim.fake.mode` 설정에 따라 성공·실패, `@ConditionalOnProperty`)
- [ ] T003 `FakeEsimProvider` 단위 테스트: ICCID 형식, 모드별 동작

## Phase 2: User Story 1 - 결제 후 자동 발급 (P1) 🎯

- [ ] T004 [US1] `Esim`, `EsimStatus`, `EsimIssueAttempt` Entity와 Repository 작성
- [ ] T005 [US1] `Esim.activationCode()` 구현과 단위 테스트 (`LPA:1$주소$매칭ID` 형식)
- [ ] T006 [US1] `EsimIssueService.issue()` 구현: 트랜잭션 1(확인·시도 기록) → 공급사 호출 → 트랜잭션 2(저장·상태 변경)
- [ ] T007 [US1] 003의 `PaymentService.confirm()` 커밋 이후에 `issue()`가 호출되도록 연결 (같은 트랜잭션에 넣지 않기)
- [ ] T008 [US1] 통합 테스트: 결제 승인 → Esim `ISSUED`, 주문 `FULFILLED`; `issue()` 두 번 호출해도 Esim 1개

## Phase 3: User Story 2 - 실패 처리와 재시도 (P1)

- [ ] T009 [US2] 실패 시 주문 `FULFILLMENT_FAILED`, attempt `FAILED` 기록 구현
- [ ] T010 [US2] `POST /api/orders/{orderNo}/esim/retry` 구현 (본인 주문 확인, 3회 한도)
- [ ] T011 [US2] 통합 테스트: 실패 모드 → `FULFILLMENT_FAILED` + 결제 기록 유지, 재시도 성공, 3회 초과 `ESIM-4003`, 남의 주문 404

## Phase 4: User Story 3 - 공급사 교체 가능 (P2)

- [ ] T012 [US3] `EsimIssueService`가 `FakeEsimProvider`를 직접 참조하지 않는지 확인 (import 검색)
- [ ] T013 [US3] `README`에 실제 공급사 구현체를 추가하는 방법 3줄 정리

## Phase 5: Polish

- [ ] T014 로그 점검: 매칭 ID와 활성화 코드 전체가 없는지, ICCID는 뒤 4자리만인지
- [ ] T015 코드 리뷰 후 PR로 `develop`에 합치기. 기능이 안정되면 `develop`을 `main`에 합치기
