# API Contract: 회원 가입과 로그인

| 기능 | Method | URI | 인증 | 성공 Status |
|------|--------|-----|------|------------|
| 회원 가입 | POST | /api/auth/signup | 불필요 | 201 Created |
| 로그인 | POST | /api/auth/login | 불필요 | 200 OK |
| 내 정보 조회 | GET | /api/users/me | 필요 | 200 OK |

## POST /api/auth/signup

**Request**

```json
{
  "email": "traveler@example.com",
  "password": "Travel123!",
  "name": "김여행"
}
```

**Response 201**

```json
{
  "success": true,
  "data": { "id": 1, "email": "traveler@example.com", "status": "ACTIVE" }
}
```

## POST /api/auth/login

**Request**

```json
{ "email": "traveler@example.com", "password": "Travel123!" }
```

**Response 200**

```json
{
  "success": true,
  "data": { "accessToken": "eyJhbGciOi...", "tokenType": "Bearer", "expiresIn": 3600 }
}
```

## GET /api/users/me

**Header**: `Authorization: Bearer eyJhbGciOi...`

**Response 200**

```json
{
  "success": true,
  "data": { "id": 1, "email": "traveler@example.com", "name": "김여행" }
}
```

## DTO

| DTO | 필드 | 검증 / 처리 |
|-----|------|------------|
| SignUpRequest | email | `@NotBlank`, `@Email`, trim 후 소문자 |
| | password | `@NotBlank`, `@Pattern` (8~50자, 영문·숫자·특수문자, 공백 불가) |
| | name | `@NotBlank`, `@Size(max = 30)` |
| SignUpResponse | id, email, status | `from(User)` 정적 팩토리 |
| LoginRequest | email, password | `@NotBlank` |
| TokenResponse | accessToken, tokenType, expiresIn | |
| MeResponse | id, email, name | `from(User)` |

## Error Codes

| 코드 | HTTP | 메시지 | 언제 |
|------|------|--------|------|
| COMMON-0001 | 400 | 입력값을 확인해주세요. | `@Valid` 실패 (필드별 이유를 함께 응답) |
| USER-1001 | 409 | 이미 가입된 이메일입니다. | 이메일 중복 |
| USER-1101 | 401 | 이메일 또는 비밀번호가 올바르지 않습니다. | 로그인 실패 |
| USER-1201 | 401 | 로그인이 필요합니다. | 토큰 없음, 만료, 위조 |
