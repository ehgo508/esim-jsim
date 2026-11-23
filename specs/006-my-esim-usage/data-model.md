# Data Model: 내 eSIM 상태와 사용량 조회

## esim_usage_snapshots

논리명: **eSIM 사용량 스냅샷**

| 논리명 | 물리명 | 타입 | 제약 | 설명 |
|--------|--------|------|------|------|
| 스냅샷 ID | `id` | BIGINT | PK, AUTO_INCREMENT |  |
| eSIM ID | `esim_id` | BIGINT | FK → esims.id, NOT NULL, UNIQUE | eSIM당 1건 |
| 데이터 총량 | `data_total_mb` | INT | NULL 허용 | 무제한이면 NULL |
| 데이터 사용량 | `data_used_mb` | INT | NOT NULL |  |
| 통화 총량 | `voice_total_min` | INT | NULL 허용 | 통화 미포함이면 NULL |
| 통화 사용량 | `voice_used_min` | INT | NULL 허용 |  |
| 문자 총량 | `sms_total` | INT | NULL 허용 | 문자 미포함이면 NULL |
| 문자 사용량 | `sms_used` | INT | NULL 허용 |  |
| 동기화일시 | `synced_at` | DATETIME(6) | NOT NULL | 공급사에서 가져온 시각 |

## esims (컬럼 추가)

| 논리명 | 물리명 | 타입 | 제약 | 설명 |
|--------|--------|------|------|------|
| 개통일시 | `activated_at` | DATETIME(6) | NULL 허용 | 현지에서 처음 연결된 시각 |
| 만료일시 | `expires_at` | DATETIME(6) | NULL 허용 | 만료 시각 |

## 전체 ERD (MVP 완성 시점)

```text
countries 1 ──── N plans
users     1 ──── N orders   N ──── 1 plans
orders    1 ──── 1 payments
orders    1 ──── N esim_issue_attempts
orders    1 ──── 1 esims    N ──── 1 users
plans     1 ──── N esims
esims     1 ──── 1 esim_usage_snapshots
```

## 인터페이스 추가

```text
interface EsimProvider
  EsimUsage getUsage(String iccid)

record EsimUsage(
  EsimStatus status,
  Integer dataTotalMb, int dataUsedMb,
  Integer voiceTotalMin, Integer voiceUsedMin,
  Integer smsTotal, Integer smsUsed,
  Instant activatedAt, Instant expiresAt )
```
