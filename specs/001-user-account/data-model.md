# Data Model: 회원 가입과 로그인

## users

논리명: **사용자**

| 논리명 | 물리명 | 타입 | 제약 | 설명 |
|--------|--------|------|------|------|
| 사용자 ID | `id` | BIGINT | PK, AUTO_INCREMENT |  |
| 이메일 | `email` | VARCHAR(255) | NOT NULL, UNIQUE | 소문자로 저장한 이메일 |
| 비밀번호 해시 | `password_hash` | VARCHAR(100) | NOT NULL | BCrypt 결과 (60자) |
| 이름 | `name` | VARCHAR(30) | NOT NULL |  |
| 계정 상태 | `status` | VARCHAR(20) | NOT NULL | `ACTIVE` (MVP 이후 `SUSPENDED`, `WITHDRAWN`) |
| 생성일시 | `created_at` | DATETIME(6) | NOT NULL | 가입 시각 (UTC) |
| 수정일시 | `updated_at` | DATETIME(6) | NOT NULL | 수정 시각 (UTC) |

## Entity: User

```text
User
- id: Long
- email: String
- passwordHash: String
- name: String
- status: UserStatus (enum: ACTIVE)
- createdAt, updatedAt: Instant   ← 공통 BaseTimeEntity로 분리 권장

생성: User.create(email, passwordHash, name)  → status = ACTIVE
기본 생성자: protected (JPA용), Setter 없음
```

## 관계 (전체 MVP 기준)

```text
User 1 ── N Order      (003)
User 1 ── N Esim       (004)
```
