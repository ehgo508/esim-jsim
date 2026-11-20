# Data Model: 국가별 요금제 조회

## countries

| 컬럼 | 타입 | 제약 | 설명 |
|------|------|------|------|
| id | BIGINT | PK | |
| code | CHAR(2) | NOT NULL, UNIQUE | ISO 국가 코드 (JP) |
| name_ko | VARCHAR(50) | NOT NULL | 일본 |
| flag_emoji | VARCHAR(10) | | 🇯🇵 |

## plans

| 컬럼 | 타입 | 제약 | 설명 |
|------|------|------|------|
| id | BIGINT | PK | |
| country_id | BIGINT | FK → countries.id, NOT NULL | |
| name | VARCHAR(100) | NOT NULL | 일본 5일 3GB |
| data_mb | INT | | 3072. 무제한이면 NULL |
| unlimited | BOOLEAN | NOT NULL | 무제한 여부 |
| validity_days | INT | NOT NULL | 5 |
| price_krw | BIGINT | NOT NULL | 9900 |
| voice_minutes | INT | NULL 허용 | 통화 포함 시에만 |
| sms_count | INT | NULL 허용 | 문자 포함 시에만 |
| status | VARCHAR(20) | NOT NULL | `ON_SALE`, `STOPPED` |
| provider_package_code | VARCHAR(100) | NOT NULL | 공급사 상품 코드 (응답에 노출 금지) |
| created_at, updated_at | DATETIME(6) | NOT NULL | |

인덱스: `(country_id, status, price_krw)`

## 초기 데이터 예시

| 국가 | 이름 | 용량 | 기간 | 가격 | 공급사 코드 |
|------|------|------|------|------|------------|
| JP | 일본 3일 1GB | 1024 | 3 | 4,900 | fake-jp-1gb-3d |
| JP | 일본 5일 3GB | 3072 | 5 | 9,900 | fake-jp-3gb-5d |
| JP | 일본 7일 무제한 | - | 7 | 19,900 | fake-jp-unl-7d |
| US | 미국 10일 5GB + 통화 100분 | 5120 | 10 | 24,900 | fake-us-5gb-10d-voice |
