# 2장. 국가별 요금제 조회 (002)

## 1. 이 기능에서 배우는 것

테이블 두 개를 연결하고(연관관계), 조건과 정렬이 있는 조회 쿼리를 만들고, JPA에서 가장 유명한 성능 문제(N+1)를 직접 본다.

## 2. 알아야 할 개념

| 개념 | 설명 | 왜 필요한가 |
|------|------|------------|
| 외래 키 (FK) | 다른 테이블의 PK를 가리키는 컬럼 | `plans.country_id` |
| `@ManyToOne` | 여러 Plan이 하나의 Country에 속함 | `Plan` 안의 `Country country` 필드 |
| 지연 로딩 (LAZY) | 연결된 객체를 실제로 쓸 때 DB에서 가져온다 | `@ManyToOne`의 기본값은 EAGER라 직접 LAZY로 바꿔야 한다 |
| N+1 문제 | 목록 1번 조회 후 각 행마다 연결 객체를 1번씩 더 조회하는 현상 | 요금제 20개 조회에 쿼리 21번 |
| fetch join / `@EntityGraph` | 연결 객체를 한 번의 쿼리로 함께 가져오는 방법 | N+1 해결 |
| JPQL과 `@Query` | 테이블이 아니라 Entity를 대상으로 쓰는 쿼리 언어 | "판매 중 요금제가 있는 국가" 조회 |
| `@Transactional(readOnly = true)` | 조회 전용 트랜잭션 | 조회 서비스의 기본 |
| enum 저장 | `@Enumerated(EnumType.STRING)`으로 문자열 저장 | 기본값 ORDINAL은 순서가 바뀌면 데이터가 망가진다 |
| `@PathVariable` | URL 경로의 값 받기 | `/api/countries/{countryCode}/plans` |
| 인덱스 | 조회를 빠르게 하는 DB 구조 | `(country_id, status, price_krw)` |
| `@DataJpaTest` | JPA 관련 Bean만 띄우는 가벼운 테스트 | Repository 쿼리 검증 |
| `@Profile` | 특정 환경에서만 Bean 활성화 | 초기 데이터는 `local`에서만 |

## 3. 공부할 문서

| 주제 | 문서 |
|------|------|
| 연관관계 매핑 | Hibernate User Guide의 "Associations" https://docs.jboss.org/hibernate/orm/current/userguide/html_single/Hibernate_User_Guide.html |
| `@Query`, `@EntityGraph` | Spring Data JPA Reference https://docs.spring.io/spring-data/jpa/reference/ |
| 프로필 | Spring Boot Reference의 "Profiles" https://docs.spring.io/spring-boot/reference/features/profiles.html |
| 국가 코드 | ISO 3166-1 alpha-2 (위키백과에 표가 있음) |

검색 키워드: `JPA N+1 문제 fetch join`, `ManyToOne LAZY 이유`, `JPA 양방향 연관관계 꼭 필요한가`, `spring.jpa.show-sql`, `EnumType.STRING`

## 4. 구현 순서와 힌트

| 작업 | 힌트 |
|------|------|
| T002 Plan Entity | 무제한 요금제는 `dataMb`가 null이다. `Integer`(객체)와 `int`(원시형)의 차이를 떠올린다 |
| T003 Repository | 메서드 이름이 너무 길어지면 `@Query`로 바꾸는 것이 읽기 좋다. "판매 요금제가 있는 국가"는 `exists` 서브쿼리나 `join` + `distinct` 두 방법이 있다. 둘 다 해 보고 SQL 로그를 비교한다 |
| T004 Repository 테스트 | 테스트 데이터를 직접 `save` 해서 만든다. 판매 중지 요금제만 있는 국가를 꼭 넣는다 |
| T008 국가별 목록 | 국가가 없는 경우(404)와 국가는 있는데 요금제가 0개인 경우(빈 배열 200)를 구분한다 |
| T011 상세 DTO | `providerPackageCode`가 응답 JSON에 없는지 테스트로 확인한다 (`jsonPath(...).doesNotExist()`) |
| T013 숫자가 아닌 ID | `/api/plans/abc`처럼 숫자 자리에 글자가 오면 Spring은 `MethodArgumentTypeMismatchException`을 던진다. 001에서 만든 `GlobalExceptionHandler`에 이 예외를 400으로 바꾸는 처리를 추가해야 테스트가 통과한다 |
| T014 초기 데이터 | 서버를 다시 띄울 때마다 중복으로 들어가지 않게 "비어 있을 때만" 조건을 둔다 |
| T016 N+1 점검 | `spring.jpa.show-sql=true`로 목록 API 호출 시 SELECT가 몇 번 나가는지 센다. 상세 응답에서 `plan.getCountry().getName()`을 쓰는 순간을 지켜본다 |

## 5. 스스로 점검할 질문

- `@ManyToOne`을 EAGER로 두면 어떤 일이 생기는가?
- 요금제 20개 목록을 조회할 때 쿼리가 21번 나갔다. 왜인가? 어떻게 1~2번으로 줄이는가?
- 용량을 GB 소수(`1.5`)가 아니라 MB 정수(`1536`)로 저장하는 이유는?
- 가격을 `double`로 다루면 안 되는 이유는?
- enum을 ORDINAL로 저장했는데 나중에 enum 중간에 값을 추가하면?
- 조회 API를 로그인 없이 열어 둘 때, 응답에 넣으면 안 되는 정보는 무엇인가?

## 6. 흔한 실수

- 양방향 연관관계(`Country`에 `List<Plan>`)를 습관적으로 만들고, JSON 변환 시 무한 순환에 빠진다. MVP는 단방향이면 충분하다.
- 트랜잭션 밖(Controller)에서 LAZY 객체에 접근해 `LazyInitializationException`이 난다. DTO 변환은 Service 안에서 한다.
- `data.sql`이 테스트에도 실행되어 테스트 결과가 달라진다.
