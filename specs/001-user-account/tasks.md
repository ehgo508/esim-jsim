---
description: "회원 가입과 로그인 작업 목록"
---

# Tasks: 회원 가입과 로그인

**Input**: `specs/001-user-account/` 의 spec.md, plan.md, data-model.md, contracts/api.md

**사용법**: 위에서부터 하나씩 직접 구현하고 `[ ]`를 `[x]`로 바꾼다. 막히면 공부 가이드 PDF의 같은 번호 장을 본다. `[P]`는 다른 사람과 동시에 해도 되는 작업이다.

## Phase 1: Setup (프로젝트 처음 만들기)

- [ ] T001 start.spring.io에서 프로젝트 생성 (Java 21, Gradle, Spring Web, Validation, Data JPA, Security, MySQL Driver, H2, Lombok 선택) → `backend/`
- [ ] T002 `docker-compose.yml`로 로컬 MySQL 띄우기, `application.yml`과 `application-local.yml` 분리 (`application-local.yml`은 `.gitignore`에 추가)
- [ ] T003 [P] GitHub 저장소 만들고 Dependabot 알림 켜기
- [ ] T004 애플리케이션 실행 후 임시 컨트롤러(`GET /hello`)로 서버가 뜨는지 확인

## Phase 2: Foundational (모든 기능이 쓰는 공통 코드)

- [ ] T005 `global/response/ApiResponse` 작성 (`success`, `data`, `error` 형식)
- [ ] T006 `global/error/ErrorCode` enum, `BusinessException` 작성
- [ ] T007 `global/error/GlobalExceptionHandler` 작성 (`BusinessException`, `MethodArgumentNotValidException` 처리)
- [ ] T008 `BaseTimeEntity` 작성 (`@CreatedDate`, `@LastModifiedDate`, JPA Auditing 켜기)

**Checkpoint**: 일부러 예외를 던지는 임시 API를 만들어 에러 응답 형식이 constitution의 형식대로 나오는지 확인

## Phase 3: User Story 1 - 회원 가입 (P1) 🎯

- [ ] T009 [US1] `user/domain/User`, `UserStatus` Entity 작성 (data-model.md 참고)
- [ ] T010 [US1] `user/repository/UserRepository` 작성 (`existsByEmail`, `findByEmail`)
- [ ] T011 [US1] `SignUpRequest`, `SignUpResponse` DTO 작성 (검증 어노테이션 포함)
- [ ] T012 [US1] `SecurityConfig`에 `PasswordEncoder` Bean 등록, `/api/auth/**` 허용
- [ ] T013 [US1] `AuthService.signUp()` 구현 (plan.md 회원 가입 흐름대로)
- [ ] T014 [US1] `AuthController` `POST /api/auth/signup` 구현
- [ ] T015 [US1] 통합 테스트: 가입 성공, 이메일 중복, 비밀번호 규칙 위반, 대소문자만 다른 이메일 중복

## Phase 4: User Story 2 - 로그인 (P1)

- [ ] T016 [US2] `JwtProvider` 작성 (토큰 생성, 검증, userId 꺼내기). 서명 키는 환경 변수에서 읽기
- [ ] T017 [US2] `LoginRequest`, `TokenResponse` DTO 작성
- [ ] T018 [US2] `AuthService.login()` 구현 (실패 시 항상 `USER-1101`)
- [ ] T019 [US2] `POST /api/auth/login` 구현
- [ ] T020 [US2] 통합 테스트: 로그인 성공, 비밀번호 틀림, 없는 이메일 (두 실패 응답이 똑같은지)

## Phase 5: User Story 3 - 내 정보 조회 (P2)

- [ ] T021 [US3] `JwtAuthenticationFilter` 작성 후 `SecurityConfig`에 등록
- [ ] T022 [US3] 인증 실패 시 `USER-1201` JSON을 응답하는 `AuthenticationEntryPoint` 작성
- [ ] T023 [US3] `GET /api/users/me` 구현 (`@AuthenticationPrincipal`)
- [ ] T024 [US3] 통합 테스트: 토큰 없음 401, 잘못된 토큰 401, 정상 토큰 200

## Phase 6: Polish

- [ ] T025 로그에 비밀번호, 토큰 전체가 찍히지 않는지 확인
- [ ] T026 팀원 코드 리뷰 후 PR로 `develop`에 합치기. 기능이 안정되면 `develop`을 `main`에 합치기

## Dependencies

- Phase 1 → Phase 2 → US1 → US2 → US3 순서로 진행
- T003은 언제 해도 됨
