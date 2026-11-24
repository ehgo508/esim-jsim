# 3장. 주문과 결제 (003)

## 1. 이 기능에서 배우는 것

우리 서버가 다른 회사 서버(토스페이먼츠)를 호출하는 방법, 돈이 오가는 로직에서 데이터가 꼬이지 않게 하는 방법(트랜잭션, 상태, 락, 멱등성). 실무에서 가장 중요하게 보는 주제들이 모여 있다.

## 2. 알아야 할 개념

### 결제 연동의 구조

| 개념 | 설명 | 왜 필요한가 |
|------|------|------------|
| PG사 | 카드사와 가맹점 사이에서 결제를 대행하는 회사. 토스페이먼츠가 PG사다 | 카드 정보를 우리가 직접 다루지 않는다 |
| 클라이언트 키 / 시크릿 키 | 클라이언트 키는 브라우저에 노출해도 되는 키, 시크릿 키는 서버만 아는 키 | 시크릿 키가 새면 남이 우리 이름으로 승인·취소 가능 |
| 결제 요청 → 인증 → 승인 | 사용자가 결제창에서 인증을 마쳐도 아직 돈이 나간 게 아니다. 서버가 승인 API를 불러야 확정된다 | `POST /api/payments/confirm`이 존재하는 이유 |
| successUrl / failUrl | 결제창이 끝나고 돌아올 우리 페이지 주소. 쿼리 파라미터로 `paymentKey`, `orderId`, `amount`가 붙어 온다 | 프론트가 이 값을 서버로 전달 |
| 금액 검증 | 브라우저에서 온 `amount`는 조작될 수 있다. 서버의 주문 금액과 비교한다 | 9,900원짜리를 100원에 사는 공격 방지 |
| 테스트 모드 | 테스트 키로는 실제 돈이 나가지 않는다 | 학습 프로젝트 |

### 외부 API 호출

| 개념 | 설명 | 왜 필요한가 |
|------|------|------------|
| `RestClient` | Spring 6.1부터 제공하는 HTTP 호출 도구 | 토스 승인 API 호출 |
| Basic 인증 | `아이디:비밀번호`를 Base64로 인코딩해 헤더에 넣는 방식 | 토스는 `시크릿키:`(비밀번호 비움)를 사용 |
| 타임아웃 | 응답을 기다리는 최대 시간 | 설정하지 않으면 상대 서버가 멈출 때 우리도 멈춘다 |
| 4xx / 5xx 응답 처리 | 외부 API의 에러 응답을 우리 예외로 바꾸기 | 토스의 실패 코드와 메시지를 저장 |
| `@ConfigurationProperties` | 설정 값을 객체로 묶어 읽기 | 키, URL, 타임아웃 |
| 인터페이스로 감싸기 | `PaymentGateway` 인터페이스 뒤에 토스 구현을 둔다 | 테스트에서 가짜로 교체 |

### 트랜잭션과 동시성

| 개념 | 설명 | 왜 필요한가 |
|------|------|------------|
| 트랜잭션 | 여러 DB 작업을 "전부 성공 또는 전부 취소"로 묶는 것 | 주문 상태 변경과 결제 기록 저장이 함께 되어야 함 |
| `@Transactional` | 메서드를 트랜잭션으로 감싼다. 런타임 예외가 나면 롤백 | Service 메서드 |
| 변경 감지 | 트랜잭션 안에서 Entity 필드를 바꾸면 커밋 때 자동 UPDATE | `order.markPaid()` 후 `save` 불필요 |
| 상태 머신 | 가능한 상태와 허용되는 전이를 정해 둔 것 | `CREATED`에서만 `PAID`로 갈 수 있다 |
| 경쟁 상태 (race condition) | 두 요청이 동시에 같은 데이터를 읽고 각자 바꾸는 상황 | 성공 페이지 새로고침, 더블 클릭 |
| 비관적 락 | 조회할 때 행을 잠가 다른 트랜잭션이 기다리게 한다 (`SELECT ... FOR UPDATE`) | 동시 승인 요청 방어 |
| 낙관적 락 | 버전 번호로 충돌을 감지하고 나중 것을 실패시킨다 (`@Version`) | 대안. 비교해서 알아두기 |
| 멱등성 | 같은 요청을 여러 번 보내도 결과가 한 번 보낸 것과 같은 성질 | 중복 승인 정책 |
| 트랜잭션과 외부 호출 | 외부 API는 롤백되지 않는다. DB가 롤백돼도 결제는 이미 승인됐을 수 있다 | 승인과 발급을 다른 트랜잭션으로 나누는 이유 |

### 트랜잭션 격리 수준

트랜잭션 여러 개가 동시에 돌 때, 한 트랜잭션이 다른 트랜잭션의 변경을 어디까지 보게 할지 정하는 설정이다. 격리를 느슨하게 하면 빠르지만 아래 세 가지 이상 현상이 생길 수 있다.

| 현상 | 무슨 일이 생기나 | 예 |
|------|----------------|----|
| Dirty read | 다른 트랜잭션이 아직 커밋하지 않은 값을 읽는다. 그 트랜잭션이 롤백하면 없던 값을 읽은 셈이 된다 | A가 주문을 `PAID`로 바꾸는 중인데(커밋 전) B가 `PAID`로 읽음. A가 롤백함 |
| Non-repeatable read | 한 트랜잭션에서 같은 행을 두 번 읽었는데 값이 달라진다. 그 사이에 다른 트랜잭션이 수정하고 커밋했기 때문이다 | A가 주문 금액을 9,900원으로 읽음 → B가 수정 후 커밋 → A가 다시 읽으니 다른 값 |
| Phantom read | 같은 조건으로 두 번 조회했는데 행의 개수가 달라진다. 그 사이에 다른 트랜잭션이 행을 추가하거나 삭제했기 때문이다 | A가 "내 주문 목록"을 조회해 3건 → B가 주문 추가 후 커밋 → A가 다시 조회하니 4건 |

Non-repeatable read는 이미 있던 행의 값이 바뀌는 것이고, Phantom read는 없던 행이 나타나거나 있던 행이 사라지는 것이다.

격리 수준은 네 단계이고, 아래로 갈수록 엄격하다 (SQL 표준 기준. O는 그 현상이 생길 수 있다는 뜻).

| 격리 수준 | Dirty read | Non-repeatable read | Phantom read |
|-----------|:---:|:---:|:---:|
| READ UNCOMMITTED | O | O | O |
| READ COMMITTED | X | O | O |
| REPEATABLE READ | X | X | O |
| SERIALIZABLE | X | X | X |

- MySQL(InnoDB)의 기본값은 REPEATABLE READ다. 이 프로젝트는 기본값을 그대로 쓰고 따로 설정하지 않는다.
- InnoDB의 REPEATABLE READ는 트랜잭션이 처음 읽은 시점의 스냅샷을 계속 보여 주기 때문에, 일반 `SELECT`에서는 표준과 달리 Phantom read도 대부분 생기지 않는다.
- 격리 수준은 "무엇을 읽게 되는가"를 정할 뿐이고, 동시 요청을 막아 주지는 않는다. 결제 승인 요청 두 개가 동시에 오면 REPEATABLE READ에서도 둘 다 주문 상태를 `CREATED`로 읽고 둘 다 승인을 진행한다. 그래서 이 프로젝트는 격리 수준을 올리지 않고 비관적 락(`SELECT ... FOR UPDATE`)과 UNIQUE 제약으로 막는다.

### 테스트

| 개념 | 설명 |
|------|------|
| Mock | 진짜 대신 넣는 가짜 객체. 정해 준 대로 응답하고, 몇 번 불렸는지 확인할 수 있다 |
| `@MockitoBean` | Spring 컨테이너의 Bean을 Mock으로 바꾼다 (Spring Boot 3.4 이상. 이전 버전은 `@MockBean`) |
| `verify(..., times(1))` | 정확히 한 번 호출됐는지 검증 |

## 3. 공부할 문서

| 주제 | 문서 |
|------|------|
| 토스페이먼츠 연동 | 토스페이먼츠 개발자센터 https://docs.tosspayments.com 의 "결제위젯 연동하기", "결제 승인 API" |
| 토스 테스트 키와 테스트 카드 | 같은 사이트의 "테스트 환경" 안내 |
| `RestClient` | Spring Framework Reference의 "REST Clients" https://docs.spring.io/spring-framework/reference/integration/rest-clients.html |
| 트랜잭션 | Spring Framework Reference의 "Transaction Management" https://docs.spring.io/spring-framework/reference/data-access/transaction.html |
| JPA 락 | Spring Data JPA Reference의 "Locking" https://docs.spring.io/spring-data/jpa/reference/ |
| 격리 수준 | MySQL Reference Manual의 "Transaction Isolation Levels" https://dev.mysql.com/doc/refman/8.0/en/innodb-transaction-isolation-levels.html |
| 설정 값 바인딩 | Spring Boot Reference의 "Externalized Configuration" https://docs.spring.io/spring-boot/reference/features/external-config.html |

검색 키워드: `토스페이먼츠 결제 승인 Spring Boot`, `@Transactional 동작 원리 프록시`, `@Transactional 같은 클래스 내부 호출`, `비관적 락 낙관적 락 차이`, `트랜잭션 격리 수준 dirty read phantom read`, `MySQL REPEATABLE READ MVCC`, `멱등성 API`, `결제 금액 검증 이유`

주의: 토스페이먼츠 API의 정확한 필드 이름과 응답 형식은 반드시 개발자센터의 현재 문서를 기준으로 한다. 명세의 예시는 구조를 설명하기 위한 것이다.

## 4. 구현 순서와 힌트

| 작업 | 힌트 |
|------|------|
| T003 Order Entity | 상태를 바꾸는 메서드 안에서 현재 상태를 검사하고, 맞지 않으면 예외를 던진다. Service에서 `if (order.getStatus() == ...)`를 반복하지 않게 된다 |
| T004 단위 테스트 | Spring 없이 `new`만으로 테스트할 수 있다. 가장 빠른 테스트다 |
| T005 주문번호 | 날짜 + 무작위 문자열. `UUID`의 일부나 `SecureRandom`을 떠올린다. 추측 가능하면 안 된다 |
| T009 결과 객체 | 성공, 결제사 거절, 타임아웃 세 경우를 어떻게 표현할지 먼저 정한다. 예외로 할지, 결과 객체로 할지. Java 21의 sealed interface도 선택지다 |
| T010 TossPaymentGateway | 먼저 Postman으로 승인 API를 직접 호출해 요청과 응답을 눈으로 본다. 그다음 코드로 옮긴다 |
| T011 락 조회 | Repository 메서드에 `@Lock`을 붙인다. 락은 트랜잭션 안에서만 의미가 있다 |
| T012 confirm | plan.md의 흐름도를 주석으로 먼저 적고, 한 단계씩 채운다. 금액 검증이 결제사 호출보다 앞에 있는지 확인한다 |
| T014 테스트 | "중복 승인" 테스트는 confirm을 두 번 호출하고 게이트웨이가 1번만 불렸는지 `verify`한다 |
| T015 실제 결제 | 프론트는 HTML 파일 하나로 충분하다. 토스 문서의 샘플 코드를 읽고 필요한 부분만 가져온다. 로컬에서는 successUrl이 `http://localhost:...`여도 된다 |

## 5. 스스로 점검할 질문

- 결제창에서 결제가 끝났는데 왜 서버가 승인 API를 또 불러야 하는가?
- 승인 요청의 `amount`를 서버가 검증하지 않으면 어떤 일이 생기는가? 구체적인 공격 순서를 말해 보라.
- 주문에 요금제 가격을 "복사"해 두는 이유는? 요금제를 참조만 하면 안 되는가?
- 시크릿 키를 프론트 코드에 넣으면 안 되는 이유는?
- 성공 페이지를 새로고침하면 서버에서 어떤 일이 일어나는가? 우리 코드는 어떻게 대응하는가?
- 토스 승인은 성공했는데 그 직후 우리 DB 저장이 실패하면 어떤 상태가 되는가? 어떻게 알아챌 수 있는가?
- 결제 승인과 eSIM 발급을 같은 `@Transactional` 안에 넣으면 왜 위험한가?
- 비관적 락 없이 UNIQUE 제약만으로 중복 승인을 막으면 무엇이 달라지는가?
- Non-repeatable read와 Phantom read의 차이를 예를 들어 설명해 보라.
- 격리 수준을 SERIALIZABLE로 올리지 않고 락으로 중복 승인을 막는 이유는?
- 타임아웃이 났을 때 주문을 `PAYMENT_FAILED`로 바꾸지 않는 이유는?

## 6. 흔한 실수

- 같은 클래스 안에서 `@Transactional` 메서드를 직접 호출해 트랜잭션이 적용되지 않는다 (프록시 원리).
- 체크 예외(`Exception`)는 기본적으로 롤백되지 않는다는 것을 모른다.
- 외부 API 호출을 긴 트랜잭션 안에 넣어 DB 커넥션을 오래 잡는다. MVP에서는 락 때문에 감수하지만, 이유는 알고 있어야 한다.
- 테스트에서 실제 토스 API를 호출한다. 통합 테스트는 Mock으로, 실제 호출은 손으로 한 번만.
- 토스의 `orderId`에 DB의 숫자 id를 넣는다. 규칙(6~64자)에 맞지 않고 추측도 쉽다.
