# Implementation Plan: 내 eSIM 상태와 사용량 조회

**Branch**: `006-my-esim-usage` | **Date**: 2026-11-20 | **Spec**: [spec.md](./spec.md)

## Summary

내 eSIM 목록과 사용량 조회 API를 만든다. `EsimProvider`에 사용량 조회를 추가하고, 결과를 스냅샷 테이블에 저장해 5분 동안 재사용한다. 캐시 개념과 장애 대응(fallback)을 연습하는 기능이다.

## Technical Context

**Language/Version**: Java 21

**Primary Dependencies**: Spring Boot 3.x, Spring Data JPA, `java.time.Clock` (시간 테스트용)

**Storage**: MySQL 8 (`esim_usage_snapshots`, `esims` 컬럼 추가)

**Testing**: JUnit 5, MockMvc, 고정 `Clock`으로 5분 경계 테스트

## Constitution Check

| 원칙 | 확인 |
|------|------|
| II. MVP First | 알림, 충전, 스케줄러, 그래프 제외 |
| III. 외부 시스템 분리 | `EsimProvider.getUsage()` 추가, 가짜 구현 제공 |
| IV. 테스트 | 5분 규칙, 장애 시 stale 응답, 통화·문자 null 처리 |
| V. 보안 | 본인 eSIM만 |

## Processing Flow

### 사용량 조회

```text
GET /api/esims/{esimId}/usage
        ↓
esimRepository.findByIdAndUserId(esimId, userId)
  없음 → USAGE-6001 (404)
        ↓
snapshot = snapshotRepository.findByEsimId(esimId)   (없을 수 있음)
        ↓
갱신이 필요한가?
  esim.status == EXPIRED 이고 snapshot 있음        → 아니오
  snapshot 있고 syncedAt + 5분 > now(clock)        → 아니오
  그 외                                            → 예
        ↓ 예
[트랜잭션 밖] esimProvider.getUsage(esim.iccid)
  ├ 성공 → EsimUsage { status, data(total, used),
  │                    voice(total, used)?, sms(total, used)?,
  │                    activatedAt?, expiresAt? }
  │        [트랜잭션] snapshot 저장 또는 갱신 (syncedAt = now)
  │                  esim.syncStatus(usage.status, activatedAt, expiresAt)
  │        stale = false
  └ 실패 → snapshot 있음 → 그대로 사용, stale = true
           snapshot 없음 → USAGE-6002 (503)
        ↓
UsageResponse.of(esim, plan, snapshot, stale, now)
  remaining = max(total - used, 0)
  voice, sms = 요금제에 포함된 경우에만
  daysLeft  = expiresAt 있으면 올림(expiresAt - now)
        ↓
200 OK
```

### 상태 보정 규칙

```text
순서: ISSUED(0) < INSTALLED(1) < ACTIVE(2) < EXPIRED(3)

esim.syncStatus(providerStatus, activatedAt, expiresAt)
  activatedAt, expiresAt 은 공급사가 값을 주면 채운다 (null 이면 그대로 둠)
  providerStatus 의 순서가 현재보다 크면 → 변경
  같거나 작으면                          → 무시 (뒤로 가지 않음)
```

## Key Decisions

| 결정 | 선택 | 고려한 다른 방법 |
|------|------|-----------------|
| 캐시 저장 위치 | DB 스냅샷 테이블 | Redis나 `@Cacheable`은 더 빠르지만, 장애 시 마지막 값을 보여주려면 영속 저장이 필요하고 설치할 것도 늘어남 |
| 갱신 방식 | 조회할 때 필요하면 갱신 (lazy) | 스케줄러로 미리 갱신은 안 보는 eSIM까지 호출해서 낭비 |
| 시간 처리 | `Clock`을 Bean으로 주입 | `Instant.now()` 직접 호출은 "5분 뒤" 테스트가 어려움 |
| 통화·문자 표현 | 포함 안 되면 `null` | 0으로 주면 "다 썼음"과 구분이 안 됨 |

## Project Structure

```text
backend/src/main/java/com/esimtravel/usage/
├── controller/MyEsimController.java
├── service/MyEsimQueryService.java, UsageSyncService.java
├── domain/EsimUsageSnapshot.java
├── repository/EsimUsageSnapshotRepository.java
└── dto/MyEsimSummaryResponse.java, UsageResponse.java

backend/src/main/java/com/esimtravel/esim/provider/
├── EsimProvider.java        (getUsage 추가)
├── EsimUsage.java           (record)
└── fake/FakeEsimProvider.java (getUsage 구현)
```
