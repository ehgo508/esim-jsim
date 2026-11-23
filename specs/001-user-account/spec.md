# Feature Specification: 회원 가입과 로그인

**Feature Branch**: `001-user-account`

**Created**: 2026-11-20

**Status**: Draft

**Input**: User description: "여행자가 이메일과 비밀번호로 가입하고 로그인해서, 자기가 산 eSIM을 자기만 볼 수 있어야 한다."

## Scope

**이 기능이 다루는 것**
- 이메일, 비밀번호, 이름으로 회원 가입
- 이메일과 비밀번호로 로그인하고 Access Token(JWT) 받기
- 로그인한 사용자의 내 정보 조회
- 이후 모든 기능(주문, 내 eSIM)에서 "누가 요청했는지" 확인하는 기반

**이 기능이 다루지 않는 것 (MVP 이후)**
- 이메일 인증번호 발송, 소셜 로그인(카카오, 구글)
- Refresh Token, 로그아웃 시 토큰 무효화
- 비밀번호 찾기, 회원 정보 수정, 탈퇴

## Policy Summary

| 항목 | 정책 |
|------|------|
| 이메일 | 필수, 이메일 형식, 대소문자 구분 없이 중복 불가 (소문자로 저장) |
| 비밀번호 | 8~50자, 영문·숫자·특수문자 각 1자 이상, 공백 불가 |
| 비밀번호 저장 | BCrypt 단방향 해시. 원문 저장·로그 금지 |
| 이름 | 필수, 1~30자 |
| 가입 상태 | 가입 즉시 `ACTIVE` |
| 로그인 실패 | "이메일 또는 비밀번호가 올바르지 않습니다." 하나의 문장으로 응답 (어느 쪽이 틀렸는지 알려주지 않음) |
| Access Token 유효시간 | 1시간 |
| 인증이 필요한 API | 요청 헤더 `Authorization: Bearer <token>` 필수 |

## User Scenarios & Testing *(mandatory)*

### User Story 1 - 회원 가입 (Priority: P1)

처음 온 여행자가 이메일, 비밀번호, 이름을 입력해 계정을 만든다.

**Why this priority**: 계정이 없으면 주문과 eSIM을 사람에게 연결할 수 없다.

**Independent Test**: 가입 API를 호출해 201 응답을 받고, DB에 비밀번호가 해시로 저장됐는지 확인한다.

**Acceptance Scenarios**:

1. **Given** 처음 쓰는 이메일, **When** 올바른 값으로 가입하면, **Then** 계정이 `ACTIVE`로 생성되고 id와 email이 응답된다.
2. **Given** 이미 가입된 이메일(대소문자만 다름 포함), **When** 가입하면, **Then** `USER-1001` 에러가 난다.
3. **Given** 규칙에 맞지 않는 비밀번호, **When** 가입하면, **Then** 400 에러와 이유가 응답된다.

---

### User Story 2 - 로그인 (Priority: P1)

가입한 사용자가 이메일과 비밀번호로 로그인해 Access Token을 받는다.

**Why this priority**: 주문과 내 eSIM 조회는 로그인한 사용자만 할 수 있다.

**Independent Test**: 가입한 계정으로 로그인해 토큰을 받고, 그 토큰으로 내 정보 조회가 되는지 확인한다.

**Acceptance Scenarios**:

1. **Given** 가입한 계정, **When** 올바른 이메일과 비밀번호로 로그인하면, **Then** Access Token과 만료 시간이 응답된다.
2. **Given** 틀린 비밀번호, **When** 로그인하면, **Then** `USER-1101` 에러가 나고 어느 값이 틀렸는지는 알려주지 않는다.

---

### User Story 3 - 내 정보 조회 (Priority: P2)

로그인한 사용자가 자기 이메일과 이름을 확인한다.

**Why this priority**: 토큰 인증이 실제로 동작하는지 확인하는 가장 단순한 API다.

**Independent Test**: 토큰 없이 호출하면 401, 토큰을 넣으면 200이 나오는지 확인한다.

**Acceptance Scenarios**:

1. **Given** 유효한 토큰, **When** 내 정보를 조회하면, **Then** id, email, name이 응답된다.
2. **Given** 토큰이 없거나 만료됨, **When** 조회하면, **Then** 401과 `USER-1201` 에러가 난다.

### Edge Cases

- 이메일 앞뒤 공백은 잘라서 저장한다. 비밀번호는 자르지 않는다 (공백이 있으면 규칙 위반).
- 동시에 같은 이메일로 두 번 가입 요청이 오면 DB의 UNIQUE 제약으로 하나만 성공해야 한다.
- 위조된 토큰, 서명이 다른 토큰은 만료 토큰과 똑같이 401로 처리한다.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: 시스템은 이메일, 비밀번호, 이름으로 계정을 만들 수 있어야 한다.
- **FR-002**: 시스템은 이메일 중복을 대소문자 구분 없이 막아야 한다.
- **FR-003**: 시스템은 비밀번호를 BCrypt 해시로만 저장해야 한다.
- **FR-004**: 시스템은 로그인 성공 시 1시간짜리 Access Token을 발급해야 한다.
- **FR-005**: 시스템은 `/api/auth/**`, 요금제 조회 API를 뺀 나머지 API에 유효한 토큰을 요구해야 한다.
- **FR-006**: 시스템은 로그인 실패 이유(이메일 없음, 비밀번호 틀림)를 구분해서 알려주면 안 된다.

### Key Entities

- **User**: 서비스 사용자. 이메일, 비밀번호 해시, 이름, 상태, 가입 시각을 가진다. 하나의 User는 여러 Order와 Esim을 가진다.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: 새 사용자가 1분 안에 가입과 로그인을 마칠 수 있다.
- **SC-002**: DB를 직접 열어봐도 비밀번호 원문을 알 수 없다.
- **SC-003**: 가입, 로그인, 내 정보 조회마다 성공 1개, 실패 3개 이상의 테스트가 모두 통과한다.

## Assumptions

- 이메일 소유 확인(인증번호)은 MVP에서 하지 않는다. 학습용이라 가짜 이메일로도 가입된다.
- 웹과 나중의 앱이 같은 토큰 방식을 쓴다.
