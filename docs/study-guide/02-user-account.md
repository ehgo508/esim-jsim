# 1장. 회원 가입과 로그인 (001)

## 1. 이 기능에서 배우는 것

DB에 데이터를 저장하고(JPA), 입력을 검증하고(Validation), 에러를 일관된 형식으로 돌려주고(예외 처리), "누가 요청했는지" 확인하는(Security, JWT) 방법. 이후 모든 기능의 기반이라 가장 오래 걸린다.

## 2. 알아야 할 개념

### 데이터베이스와 JPA

| 개념 | 설명 | 왜 필요한가 |
|------|------|------------|
| 테이블, 행, 열, PK | 관계형 DB의 기본. PK는 행을 구분하는 고유 값 | `users` 테이블 |
| UNIQUE 제약 | 같은 값이 두 번 들어가지 못하게 DB가 막는다 | 이메일 중복 방지의 최후 방어선 |
| JPA와 Entity | 자바 객체를 테이블 행과 연결하는 기술. `@Entity` 클래스 = 테이블 | SQL을 직접 쓰지 않고 `save()`, `findBy...()` |
| Spring Data JPA | 인터페이스만 만들면 구현을 자동으로 만들어 준다 | `UserRepository extends JpaRepository<User, Long>` |
| 메서드 이름 쿼리 | `findByEmail`, `existsByEmail`처럼 이름 규칙으로 쿼리가 만들어진다 | 대부분의 조회 |
| 영속성 컨텍스트 | JPA가 Entity를 관리하는 공간. 트랜잭션 안에서 Entity를 바꾸면 자동으로 UPDATE | 3장에서 중요해짐 |
| `ddl-auto` | Entity를 보고 테이블을 자동 생성하는 옵션 | 개발 중에는 `update`, 테스트는 `create-drop` |

### 입력 검증과 예외 처리

| 개념 | 설명 | 왜 필요한가 |
|------|------|------------|
| Bean Validation | `@NotBlank`, `@Email`, `@Size`, `@Pattern`을 DTO 필드에 붙인다 | 명세의 "검증" 칸 |
| `@Valid` | Controller 파라미터에 붙이면 검증이 실행된다 | 빠뜨리면 검증이 안 됨 |
| 정규식 | 문자열 규칙을 표현하는 문법 | 비밀번호 규칙 |
| 사용자 정의 예외 | `BusinessException(ErrorCode)` 같은 내 예외 클래스 | 업무 규칙 위반을 표현 |
| `@RestControllerAdvice` | 모든 Controller에서 난 예외를 한 곳에서 잡아 응답으로 바꾼다 | 에러 응답 형식 통일 |

### 비밀번호와 인증

| 개념 | 설명 | 왜 필요한가 |
|------|------|------------|
| 해시 | 원문을 되돌릴 수 없는 값으로 바꾸는 것 | DB가 털려도 비밀번호 원문은 안전 |
| BCrypt | 비밀번호용 해시 알고리즘. 같은 비밀번호도 매번 다른 결과(salt) | `PasswordEncoder.encode()`, `matches()` |
| 인증과 인가 | 인증 = 누구인지 확인, 인가 = 그 사람이 해도 되는지 확인 | 401과 403의 차이 |
| Spring Security 필터 체인 | 요청이 Controller에 닿기 전에 거치는 검문소들 | JWT 필터를 여기에 끼움 |
| JWT | 서버가 서명한 토큰. 안에 userId와 만료 시각이 들어 있다. 서버는 서명만 확인하면 된다 | 세션 저장소 없이 로그인 유지 |
| JWT 구조 | `헤더.내용.서명` 세 부분. 내용은 누구나 읽을 수 있으므로 비밀을 넣으면 안 된다 | 토큰에 비밀번호를 넣지 않는 이유 |
| Stateless | 서버가 로그인 상태를 기억하지 않음 | `SessionCreationPolicy.STATELESS` |
| CSRF, CORS | CSRF는 쿠키 기반 공격 방어, CORS는 다른 주소의 프론트가 API를 부를 수 있게 허용하는 설정 | JWT API에서는 CSRF를 끄고, 프론트 주소를 CORS에 등록 |

### 테스트

| 개념 | 설명 |
|------|------|
| JUnit 5 | 테스트 프레임워크. `@Test` |
| given / when / then | 준비, 실행, 검증 3단계로 테스트를 쓰는 관례. 명세의 Acceptance Scenario와 같은 형식 |
| `@SpringBootTest` + MockMvc | 서버 전체를 띄우고 가짜 HTTP 요청을 보내는 통합 테스트 |
| AssertJ | `assertThat(x).isEqualTo(y)` 형식의 검증 도구 |
| 성공 1, 실패 3 규칙 | 이 프로젝트는 API마다 성공 테스트 1개와 원인이 서로 다른 실패 테스트 3개 이상을 쓴다. 실패 원인은 보통 입력 오류(400), 인증 없음(401), 남의 것이거나 없음(404), 상태 충돌(409), 외부 시스템 오류에서 찾는다. 실패 쪽이 더 많은 이유는 버그와 보안 문제가 대부분 실패 경로에서 나오기 때문이다 |
| 테스트 격리 | 테스트끼리 데이터가 섞이지 않게 하는 것. `@Transactional` 또는 매번 DB 비우기 |

## 3. 공부할 문서

| 주제 | 문서 |
|------|------|
| JPA 첫걸음 | Spring 가이드 "Accessing Data with JPA" https://spring.io/guides/gs/accessing-data-jpa |
| MySQL 연결 | Spring 가이드 "Accessing data with MySQL" https://spring.io/guides/gs/accessing-data-mysql |
| 입력 검증 | Spring 가이드 "Validating Form Input" https://spring.io/guides/gs/validating-form-input |
| Spring Data JPA 쿼리 메서드 | https://docs.spring.io/spring-data/jpa/reference/ 의 "Query Methods" |
| Spring Security 구조 | https://docs.spring.io/spring-security/reference/ 의 "Servlet Applications → Architecture" |
| JWT 눈으로 보기 | https://jwt.io (토큰을 붙여 넣으면 내용을 보여 줌) |
| 테스트 | Spring Boot Reference의 "Testing" https://docs.spring.io/spring-boot/reference/testing/ |
| 비밀번호 저장 | OWASP "Password Storage Cheat Sheet" https://cheatsheetseries.owasp.org |

검색 키워드: `Spring Security 6 SecurityFilterChain JWT`, `OncePerRequestFilter`, `@RestControllerAdvice 예외 처리`, `JPA Entity 기본 생성자 protected 이유`, `Spring Boot 3 JWT 로그인 구현`

주의: Spring Security는 버전에 따라 설정 문법이 크게 다르다. 검색 결과가 `WebSecurityConfigurerAdapter`를 쓰고 있으면 옛날(5.x) 자료다. Spring Boot 3은 `SecurityFilterChain` Bean을 등록하는 방식이다.

## 4. 구현 순서와 힌트

| 작업 | 힌트 |
|------|------|
| T001~T004 프로젝트 생성 | Security 의존성을 넣으면 모든 URL이 로그인 화면으로 막힌다. 처음에는 놀라지 말고, T012에서 설정을 만들 때까지 임시로 전부 허용해 둔다 |
| T005 ApiResponse | 제네릭 `ApiResponse<T>`와 정적 메서드 `success(data)`, `fail(code, message)`를 떠올려 본다 |
| T006~T007 예외 처리 | `ErrorCode` enum이 HTTP 상태, 코드 문자열, 메시지를 갖게 하면 핸들러가 단순해진다. `@Valid` 실패는 `MethodArgumentNotValidException`으로 온다 |
| T009 User Entity | Setter를 만들지 않는다. 생성은 정적 메서드 `create()`로. JPA는 기본 생성자가 필요하므로 `protected`로 둔다 |
| T011 DTO | 이메일을 소문자로 바꾸는 일은 어디서 할지 정한다 (DTO 생성 시점 또는 Service). 한 곳에서만 한다 |
| T013 signUp | "중복 확인 후 저장" 사이에 다른 요청이 끼어들 수 있다. DB UNIQUE 위반 예외(`DataIntegrityViolationException`)도 `USER-1001`로 바꿔야 한다 |
| T016 JwtProvider | 서명 키는 충분히 길어야 한다(HS256은 32바이트 이상). 키를 코드에 쓰지 말고 `application-local.yml`이나 환경 변수로 |
| T018 login | 이메일이 없을 때와 비밀번호가 틀릴 때 같은 예외를 던진다 |
| T021 필터 | 필터 안에서 난 예외는 `@RestControllerAdvice`가 잡지 못한다. 그래서 T022의 `AuthenticationEntryPoint`가 따로 필요하다 |
| T023 내 정보 | 필터에서 `SecurityContext`에 넣은 값이 Controller의 `@AuthenticationPrincipal`로 온다. 무엇을 넣을지(userId만 넣을지, 객체를 넣을지) 먼저 정한다 |
| T003-1, T024-1 프론트 연결 | React 개발 서버(5173)와 Spring 서버(8080)는 주소가 달라 브라우저가 요청을 막는다. 이것이 CORS다. `SecurityConfig`에서 허용 주소를 등록한다. 토큰은 요청마다 `Authorization` 헤더에 붙인다. 응답 타입은 제네릭 `ApiResponse<T>` 하나를 만들어 두면 모든 API에 재사용할 수 있다. 백엔드의 `ApiResponse<T>`와 같은 생각이다 |

## 5. 스스로 점검할 질문

- 비밀번호를 암호화(되돌릴 수 있음)가 아니라 해시(되돌릴 수 없음)로 저장하는 이유는? 그러면 로그인 때는 어떻게 비교하는가?
- 같은 비밀번호를 BCrypt로 두 번 해시하면 결과가 다른데, `matches()`는 어떻게 맞는지 아는가?
- 로그인 실패 시 "없는 이메일입니다"라고 알려주면 어떤 공격이 쉬워지는가?
- JWT의 내용(payload)은 암호화되어 있는가? 그럼 무엇이 위조를 막는가?
- Access Token 유효시간을 1시간으로 둔 이유는? 30일로 하면 무엇이 위험한가?
- `existsByEmail`로 확인했는데도 DB UNIQUE 제약이 필요한 이유는?
- Entity를 그대로 응답으로 내보내면 안 되는 이유를 `passwordHash`를 예로 설명해 보라.
- `@Valid`를 빼먹으면 어떤 테스트가 실패하는가?

## 6. 흔한 실수

- `@Valid`를 안 붙여서 검증이 조용히 건너뛰어진다.
- `application.yml`에 DB 비밀번호와 JWT 키를 적어 GitHub에 올린다. 올렸다면 키를 바꿔야 한다. 지워도 기록에 남는다.
- `SecurityConfig`에서 `permitAll` 경로를 잘못 적어 가입 API가 401이 난다. 경로와 HTTP 메서드를 확인한다.
- 테스트가 서로의 데이터에 영향을 줘서 혼자 돌리면 성공, 같이 돌리면 실패한다.
- H2와 MySQL의 차이로 테스트는 통과하는데 로컬에서 실패한다. `user`는 H2 예약어라 테이블 이름을 `users`로 한다.
