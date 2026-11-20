# Implementation Plan: 회원 가입과 로그인

**Branch**: `001-user-account` | **Date**: 2026-11-20 | **Spec**: [spec.md](./spec.md)

## Summary

이메일/비밀번호 회원 가입, 로그인, JWT 기반 인증을 만든다. 이후 모든 기능이 쓰는 공통 기반(응답 형식, 에러 처리, 보안 설정)도 여기서 같이 만든다.

## Technical Context

**Language/Version**: Java 21

**Primary Dependencies**: Spring Boot 3.x (Web, Validation, Data JPA, Security), jjwt 또는 spring-security-oauth2-resource-server의 JWT 지원

**Storage**: MySQL 8 (`users` 테이블), 테스트는 H2

**Testing**: JUnit 5, MockMvc, AssertJ

**Target Platform**: Linux 서버 (로컬은 개발자 PC)

**Project Type**: web-service (REST API)

**Performance Goals**: 학습용이라 별도 목표 없음

**Constraints**: 비밀번호 원문과 토큰 서명 키를 로그·Git에 남기지 않음

**Scale/Scope**: 팀원과 지인 수준 (수십 명)

## Constitution Check

| 원칙 | 확인 |
|------|------|
| I. 사람이 직접 구현 | tasks.md의 작업을 팀원이 직접 구현 |
| II. MVP First | 이메일 인증, 소셜 로그인, Refresh Token 제외 |
| III. 외부 시스템 분리 | 해당 없음 |
| IV. 테스트 | 가입·로그인·내 정보 각각 성공/실패 통합 테스트 |
| V. 보안 | BCrypt, JWT 서명 키는 환경 변수 |

## Processing Flow

### 회원 가입

```text
POST /api/auth/signup
        ↓
SignUpRequest Validation (@Valid)
  이메일 형식, 비밀번호 규칙, 이름 길이
        ↓
email → trim → 소문자 변환
        ↓
userRepository.existsByEmail(email)
  true → USER-1001 (409 Conflict)
        ↓
password → BCryptPasswordEncoder.encode → passwordHash
        ↓
User.create(email, passwordHash, name)
  status = ACTIVE
        ↓
userRepository.save(user)
  (동시 요청으로 UNIQUE 위반 시 USER-1001)
        ↓
SignUpResponse.from(user)
        ↓
201 Created
```

### 로그인

```text
POST /api/auth/login
        ↓
email → trim → 소문자
        ↓
userRepository.findByEmail(email)
  없음 → USER-1101 (401)
        ↓
passwordEncoder.matches(password, user.passwordHash)
  false → USER-1101 (401)   ← 위와 같은 코드·문장
        ↓
jwtProvider.createAccessToken(user.id)
  subject = userId, 만료 = 지금 + 1시간
        ↓
200 OK { accessToken, tokenType: "Bearer", expiresIn: 3600 }
```

### 인증이 필요한 요청

```text
요청 → JwtAuthenticationFilter
        ↓
Authorization 헤더에서 "Bearer " 뒤 토큰 꺼내기
  없음 → 인증 없이 다음 필터로 (보호된 URL이면 Security가 401)
        ↓
jwtProvider.validate(token)
  서명 불일치·만료 → 401 USER-1201
        ↓
userId → SecurityContext에 저장
        ↓
Controller에서 @AuthenticationPrincipal로 userId 사용
```

## Key Decisions

| 결정 | 선택 | 고려한 다른 방법 |
|------|------|-----------------|
| 인증 방식 | JWT Access Token | 세션 방식은 웹만 쓰면 더 쉽지만, 나중의 앱과 공유하기 불편함 |
| 토큰 저장(프론트) | 메모리 또는 localStorage (학습용) | HttpOnly 쿠키가 더 안전함. MVP 이후 검토 |
| 이메일 중복 비교 | 소문자로 저장 후 UNIQUE | DB collation에 맡기는 방법은 DB마다 달라 헷갈림 |
| 공통 에러 처리 | `@RestControllerAdvice` + `BusinessException(ErrorCode)` | 컨트롤러마다 try-catch는 중복이 많음 |

## Project Structure

### Documentation (this feature)

```text
specs/001-user-account/
├── spec.md
├── plan.md
├── data-model.md
├── contracts/api.md
└── tasks.md
```

### Source Code (repository root)

```text
backend/
├── build.gradle
└── src/
    ├── main/java/com/esimtravel/
    │   ├── EsimTravelApplication.java
    │   ├── global/
    │   │   ├── response/      # ApiResponse, ErrorResponse
    │   │   ├── error/         # ErrorCode, BusinessException, GlobalExceptionHandler
    │   │   ├── security/      # SecurityConfig, JwtProvider, JwtAuthenticationFilter
    │   │   └── config/
    │   └── user/
    │       ├── controller/    # AuthController, UserController
    │       ├── service/       # AuthService
    │       ├── domain/        # User, UserStatus
    │       ├── repository/    # UserRepository
    │       └── dto/           # SignUpRequest, SignUpResponse, LoginRequest, TokenResponse, MeResponse
    └── test/java/com/esimtravel/user/
```

프론트엔드는 저장소 루트의 `frontend/`(React, TypeScript, Vite)에 둔다. API 응답 타입은 `frontend/src/api/types.ts` 같은 한 곳에 모은다. 화면 작업은 각 기능의 tasks.md에서 "프론트" 작업으로 표시한다.

**Structure Decision**: 기능(도메인)별 패키지. 001~006이 각각 `user`, `plan`, `order`, `esim`, `install`, `usage` 패키지가 된다. 공통 코드는 `global`.
