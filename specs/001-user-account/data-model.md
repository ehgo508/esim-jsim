# Data Model: 회원 가입과 로그인

## users

| 컬럼 | 타입 | 제약 | 설명 |
|------|------|------|------|
| id | BIGINT | PK, AUTO_INCREMENT | 사용자 ID |
| email | VARCHAR(255) | NOT NULL, UNIQUE | 소문자로 저장한 이메일 |
| password_hash | VARCHAR(100) | NOT NULL | BCrypt 결과 (60자) |
| name | VARCHAR(30) | NOT NULL | 이름 |
| status | VARCHAR(20) | NOT NULL | `ACTIVE` (MVP 이후 `SUSPENDED`, `WITHDRAWN`) |
| created_at | DATETIME(6) | NOT NULL | 가입 시각 (UTC) |
| updated_at | DATETIME(6) | NOT NULL | 수정 시각 (UTC) |

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
