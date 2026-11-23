# Data Model: 국가별 요금제 조회

## countries

논리명: **국가**

| 논리명 | 물리명 | 타입 | 제약 | 설명 |
|--------|--------|------|------|------|
| 국가 ID | `id` | BIGINT | PK, AUTO_INCREMENT |  |
| 국가 코드 | `code` | CHAR(2) | NOT NULL, UNIQUE | ISO 3166-1 alpha-2 (예: JP) |
| 국가명(한글) | `name_ko` | VARCHAR(50) | NOT NULL | 예: 일본 |
| 국기 이모지 | `flag_emoji` | VARCHAR(10) | NULL 허용 | 예: 🇯🇵 |

## plans

논리명: **요금제**

| 논리명 | 물리명 | 타입 | 제약 | 설명 |
|--------|--------|------|------|------|
| 요금제 ID | `id` | BIGINT | PK, AUTO_INCREMENT |  |
| 국가 ID | `country_id` | BIGINT | FK → countries.id, NOT NULL |  |
| 요금제명 | `name` | VARCHAR(100) | NOT NULL | 예: 일본 5일 3GB |
| 데이터 용량 | `data_mb` | INT | NULL 허용 | MB 단위 (예: 3072). 무제한이면 NULL |
| 무제한 여부 | `unlimited` | BOOLEAN | NOT NULL |  |
| 사용 기간 | `validity_days` | INT | NOT NULL | 일 단위 (예: 5) |
| 가격 | `price_krw` | BIGINT | NOT NULL | 원 단위, 부가세 포함 (예: 9900) |
| 통화 제공량 | `voice_minutes` | INT | NULL 허용 | 분 단위. 통화 포함 시에만 |
| 문자 제공량 | `sms_count` | INT | NULL 허용 | 건수. 문자 포함 시에만 |
| 판매 상태 | `status` | VARCHAR(20) | NOT NULL | `ON_SALE`, `STOPPED` |
| 공급사 상품 코드 | `provider_package_code` | VARCHAR(100) | NOT NULL | 공급사 상품 코드 (응답에 노출 금지) |
| 생성일시 | `created_at` | DATETIME(6) | NOT NULL |  |
| 수정일시 | `updated_at` | DATETIME(6) | NOT NULL |  |

인덱스: `(country_id, status, price_krw)`

## 초기 데이터 예시

| 국가 | 이름 | 용량 | 기간 | 가격 | 공급사 코드 |
|------|------|------|------|------|------------|
| JP | 일본 3일 1GB | 1024 | 3 | 4,900 | fake-jp-1gb-3d |
| JP | 일본 5일 3GB | 3072 | 5 | 9,900 | fake-jp-3gb-5d |
| JP | 일본 7일 무제한 | - | 7 | 19,900 | fake-jp-unl-7d |
| US | 미국 10일 5GB + 통화 100분 | 5120 | 10 | 24,900 | fake-us-5gb-10d-voice |
