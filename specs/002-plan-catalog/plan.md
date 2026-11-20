# Implementation Plan: 국가별 요금제 조회

**Branch**: `002-plan-catalog` | **Date**: 2026-11-20 | **Spec**: [spec.md](./spec.md)

## Summary

국가와 요금제 테이블을 만들고, 로그인 없이 볼 수 있는 조회 API 3개를 만든다. JPA 연관관계와 조회 쿼리를 처음 연습하는 기능이다.

## Technical Context

**Language/Version**: Java 21

**Primary Dependencies**: Spring Boot 3.x, Spring Data JPA

**Storage**: MySQL 8 (`countries`, `plans`), 초기 데이터는 `data.sql` 또는 `CommandLineRunner`

**Testing**: JUnit 5, `@DataJpaTest`, MockMvc

**Project Type**: web-service (REST API)

**Constraints**: 조회 API는 인증 없이 허용 (`SecurityConfig`에 `GET /api/countries/**`, `GET /api/plans/**` 추가)

## Constitution Check

| 원칙 | 확인 |
|------|------|
| II. MVP First | 공급사 동기화, 관리자 화면 제외 |
| III. 외부 시스템 분리 | `providerPackageCode`만 저장하고 공급사 호출은 하지 않음 |
| IV. 테스트 | Repository 쿼리 테스트 + API 테스트 |

## Processing Flow

### 국가별 요금제 목록

```text
GET /api/countries/{countryCode}/plans
        ↓
countryCode → 대문자 변환
        ↓
countryRepository.findByCode(code)
  없음 → PLAN-2001 (404)
        ↓
planRepository.findByCountryAndStatusOrderByPriceAsc(country, ON_SALE)
        ↓
List<PlanSummaryResponse> 로 변환
  dataMb → "3GB" 표시용 값은 프론트에서 계산하거나 응답에 dataLabel로 포함
        ↓
200 OK
```

### 국가 목록

```text
GET /api/countries
        ↓
countryRepository.findAllHavingOnSalePlans()
  (JPQL: plans 중 ON_SALE이 존재하는 country만, 이름순)
        ↓
200 OK
```

## Key Decisions

| 결정 | 선택 | 고려한 다른 방법 |
|------|------|-----------------|
| 국가 PK | 숫자 id + `code` UNIQUE | 국가 코드를 PK로 쓰는 방법도 있지만 JPA 연습에는 숫자 PK가 일관됨 |
| 용량 단위 | MB 정수 | GB 소수(`double`)는 비교·합계에서 오차 |
| 연관관계 | `Plan` → `Country` `@ManyToOne(fetch = LAZY)` 단방향 | 양방향은 MVP에서 필요 없음 |
| 초기 데이터 | `local` 프로필에서만 실행되는 `CommandLineRunner` | `data.sql`은 간단하지만 테스트에도 섞여 들어가기 쉬움 |

## Project Structure

```text
backend/src/main/java/com/esimtravel/plan/
├── controller/PlanController.java
├── service/PlanQueryService.java
├── domain/Country.java, Plan.java, PlanStatus.java
├── repository/CountryRepository.java, PlanRepository.java
├── dto/CountryResponse.java, PlanSummaryResponse.java, PlanDetailResponse.java
└── init/PlanDataInitializer.java   (@Profile("local"))
```
