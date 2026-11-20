---
description: "주문과 결제 작업 목록"
---

# Tasks: 주문과 결제

**Input**: `specs/003-order-payment/` 문서 전체. **선행**: 001(로그인), 002(요금제)

## Phase 1: Setup

- [ ] T001 토스페이먼츠 개발자센터 가입, 테스트 클라이언트 키·시크릿 키 확인
- [ ] T002 시크릿 키를 환경 변수 `TOSS_SECRET_KEY`로 설정하고 `@ConfigurationProperties`로 읽기 (Git에 넣지 않기)

## Phase 2: User Story 1 - 주문 만들기 (P1) 🎯

- [ ] T003 [US1] `Order`, `OrderStatus` Entity 작성 (상태 변경 메서드 포함, data-model.md 참고)
- [ ] T004 [US1] `Order` 단위 테스트: `CREATED`가 아닐 때 `markPaid()` 호출하면 예외
- [ ] T005 [US1] `orderNo` 생성 규칙 구현 (6~64자, 영문·숫자·`-`)
- [ ] T006 [US1] `OrderService.create()`와 `POST /api/orders` 구현
- [ ] T007 [US1] 통합 테스트: 주문 성공, 판매 중지 요금제, 로그인 없이 401

## Phase 3: User Story 2 - 결제 승인 (P1)

- [ ] T008 [US2] `Payment` Entity, `PaymentRepository` 작성
- [ ] T009 [US2] `PaymentGateway` 인터페이스와 결과 객체 `PaymentConfirmResult`(성공/실패/타임아웃) 설계
- [ ] T010 [US2] `TossPaymentGateway` 구현 (`RestClient`, Basic 인증 헤더, 타임아웃 설정)
- [ ] T011 [US2] `OrderRepository`에 비관적 락 조회 메서드 추가
- [ ] T012 [US2] `PaymentService.confirm()` 구현 (plan.md 결제 승인 흐름대로)
- [ ] T013 [US2] `POST /api/payments/confirm` 구현
- [ ] T014 [US2] 통합 테스트 (`PaymentGateway`는 `@MockitoBean`): 성공, 금액 조작, 중복 승인 시 게이트웨이 1번만 호출, 결제사 실패, 타임아웃
- [ ] T015 [US2] 간단한 프론트 페이지(결제위젯 + successUrl/failUrl 페이지)로 테스트 카드 실제 결제 해보기

## Phase 4: User Story 3 - 결제 실패 처리 (P2)

- [ ] T016 [US3] `POST /api/payments/fail` 구현
- [ ] T017 [US3] 통합 테스트: `CREATED` → `PAYMENT_FAILED`, 이미 `PAID`면 변경 안 됨

## Phase 5: User Story 4 - 내 주문 조회 (P2)

- [ ] T018 [US4] `GET /api/orders`, `GET /api/orders/{orderNo}` 구현
- [ ] T019 [US4] 통합 테스트: 최신순, 남의 주문 404

## Phase 6: Polish

- [ ] T020 로그에 시크릿 키, 카드 정보가 없는지 확인
- [ ] T021 코드 리뷰 후 PR로 `develop`에 합치기. 기능이 안정되면 `develop`을 `main`에 합치기
