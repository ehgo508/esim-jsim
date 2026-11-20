# 0장. Spring 기초

## 1. 이 장에서 배우는 것

Java 문법만 아는 상태에서 "브라우저가 요청하면 JSON을 돌려주는 서버"를 띄우고, Spring 프로젝트의 기본 구조를 이해한다.

## 2. 알아야 할 개념

### 웹 서버와 HTTP

| 개념 | 설명 | 왜 필요한가 |
|------|------|------------|
| 클라이언트와 서버 | 브라우저나 앱(클라이언트)이 요청을 보내고 서버가 응답한다 | 우리가 만드는 것은 서버다 |
| HTTP 메서드 | GET(조회), POST(생성), PUT/PATCH(수정), DELETE(삭제) | API 표의 Method 칸 |
| 상태 코드 | 200 성공, 201 생성됨, 400 잘못된 요청, 401 인증 필요, 404 없음, 409 충돌, 500 서버 오류 | 명세의 "성공 Status", 에러 코드 표 |
| 헤더와 바디 | 헤더는 부가 정보(인증 토큰 등), 바디는 실제 데이터 | `Authorization` 헤더, JSON 바디 |
| JSON | `{ "key": "value" }` 형식의 데이터 표현 | 모든 요청과 응답 |
| REST API | URL은 "무엇"(자원), 메서드는 "어떻게"로 설계하는 관례 | `/api/orders`, `/api/esims/5/usage` |

### Spring의 핵심 아이디어

| 개념 | 설명 | 왜 필요한가 |
|------|------|------------|
| Spring Boot | 설정을 대부분 자동으로 해 주는 Spring 시작 도구 | `main` 메서드 하나로 서버가 뜬다 |
| Bean | Spring이 만들어서 보관하는 객체 | `@Service`, `@Repository`, `@Component`가 붙은 클래스 |
| DI (의존성 주입) | 필요한 객체를 내가 `new` 하지 않고 Spring이 생성자에 넣어 준다 | 004에서 진짜·가짜 공급사를 바꿔 끼우는 원리 |
| IoC 컨테이너 | Bean을 만들고 서로 연결해 주는 Spring의 중심부 | "왜 new를 안 했는데 객체가 있지?"의 답 |
| 어노테이션 | `@RestController`처럼 `@`로 시작하는 표시. Spring이 이를 보고 동작을 붙인다 | Spring 코드의 대부분 |

### 계층 구조 (가장 중요)

```text
요청 → Controller → Service → Repository → DB
            ↓           ↓          ↓
          DTO 변환   업무 규칙   SQL 실행
```

| 계층 | 책임 | 하면 안 되는 것 |
|------|------|----------------|
| Controller | URL 연결, 요청 값 받기, 응답 만들기 | 업무 규칙 판단, DB 직접 접근 |
| Service | 업무 규칙, 트랜잭션, 여러 Repository 조합 | HTTP 관련 코드(상태 코드, 헤더) |
| Repository | DB에서 꺼내고 저장 | 업무 규칙 |
| Domain (Entity) | 데이터와 그 데이터의 규칙 (예: 주문 상태 변경) | 다른 계층 호출 |
| DTO | 계층 사이, 서버와 클라이언트 사이에 주고받는 데이터 묶음 | 로직 |

### 도구

| 도구 | 설명 |
|------|------|
| Gradle | 라이브러리를 내려받고 빌드하는 도구. `build.gradle`에 의존성을 적는다 |
| IntelliJ IDEA | Java 개발 도구. Community 버전은 무료 |
| Git / GitHub | 코드 버전 관리와 협업. 브랜치, 커밋, Pull Request |
| Postman 또는 IntelliJ HTTP Client | 브라우저 없이 API를 호출해 보는 도구 |
| Docker | MySQL을 내 PC에 설치하지 않고 띄우는 도구 |

## 3. 공부할 문서

| 주제 | 문서 | 비고 |
|------|------|------|
| 첫 서버 띄우기 | Spring 공식 가이드 "Building a RESTful Web Service" https://spring.io/guides/gs/rest-service | 15분. 가장 먼저 |
| 프로젝트 생성 | Spring Initializr https://start.spring.io | 의존성 고르기 |
| Spring Boot 전반 | Spring Boot Reference https://docs.spring.io/spring-boot/ | 사전처럼 찾아보기 |
| HTTP 기초 | MDN "HTTP 개요" https://developer.mozilla.org/ko/docs/Web/HTTP | 한국어 |
| Git 협업 | GitHub Docs "GitHub flow" https://docs.github.com/ko/get-started | 브랜치와 PR |
| 한국어 입문 강의 | 검색: "스프링 입문 코드로 배우는 스프링 부트" | 무료 입문 강의가 여럿 있음 |

검색 키워드: `스프링 DI 생성자 주입`, `Controller Service Repository 역할`, `REST API 설계 규칙`, `Gradle 의존성 implementation`

## 4. 연습 과제 (001 시작 전에)

1. start.spring.io에서 Spring Web만 넣은 프로젝트를 만들고 `GET /hello`가 `{"message": "hello"}`를 응답하게 한다.
2. `GET /hello?name=진행`이 `{"message": "hello 진행"}`을 응답하게 한다. (`@RequestParam`)
3. `POST /echo`에 JSON을 보내면 그대로 돌려주게 한다. (`@RequestBody`, DTO 클래스)
4. 인사말을 만드는 로직을 `GreetingService`로 옮기고 Controller가 생성자로 주입받게 한다.
5. 팀원 각자 브랜치를 만들어 PR을 올리고 서로 리뷰해 본다.

## 5. 스스로 점검할 질문

- `@RestController`와 `@Controller`는 무엇이 다른가?
- Controller에서 Service를 `new GreetingService()`로 만들면 안 되는 이유는?
- 필드 주입(`@Autowired` 필드)보다 생성자 주입을 권하는 이유는?
- 400과 404와 409는 각각 언제 쓰는가?
- GET 요청에 바디를 넣지 않는 이유는?
- `build.gradle`의 `implementation`과 `testImplementation`은 무엇이 다른가?

## 6. 흔한 실수

- 패키지를 `main` 클래스보다 바깥에 만들어 Bean을 못 찾는다. 모든 클래스는 `EsimTravelApplication`이 있는 패키지 아래에 둔다.
- 포트 8080이 이미 사용 중이라 서버가 안 뜬다. 이전에 띄운 서버를 끄거나 `server.port`를 바꾼다.
- DTO에 기본 생성자나 getter가 없어 JSON 변환이 실패한다. record를 쓰면 편하다.
- 에러 로그를 끝까지 읽지 않는다. 맨 아래 `Caused by:` 줄이 진짜 원인이다.
