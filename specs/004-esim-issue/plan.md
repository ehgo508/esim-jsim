# Implementation Plan: eSIM 발급

**Branch**: `004-esim-issue` | **Date**: 2026-11-20 | **Spec**: [spec.md](./spec.md)

## Summary

결제 완료 주문에 대해 `EsimProvider` 인터페이스로 eSIM을 발급받아 저장한다. 인터페이스와 구현체 분리(DI), 트랜잭션 경계, 실패 복구를 연습하는 기능이다.

## Technical Context

**Language/Version**: Java 21

**Primary Dependencies**: Spring Boot 3.x, Spring Data JPA

**Storage**: MySQL 8 (`esims`, `esim_issue_attempts`)

**Testing**: JUnit 5, MockMvc, 테스트용 `EsimProvider` 가짜 구현

**Constraints**: 공급사 호출은 DB 트랜잭션 밖에서 한다 (외부 호출이 느리면 DB 커넥션을 오래 잡기 때문)

## Constitution Check

| 원칙 | 확인 |
|------|------|
| II. MVP First | 실제 공급사, 웹훅, 자동 환불 제외 |
| III. 외부 시스템 분리 | `EsimProvider` 인터페이스 + `FakeEsimProvider`. 이 기능의 핵심 |
| IV. 테스트 | 성공, 실패, 중복 발급 방지, 재시도 한도 |
| V. 보안 | 활성화 코드 로그 금지 |

## Processing Flow

### 발급

```text
PaymentService.confirm() 트랜잭션 커밋 (order = PAID)
        ↓
esimIssueService.issue(orderId)
        ↓
[트랜잭션 1] 주문 조회
  esimRepository.existsByOrderId(orderId) → 이미 있음 → 종료
  order.status 가 PAID 또는 FULFILLMENT_FAILED 가 아님 → 종료
  시도 횟수 >= 3 → ESIM-4003
  attempt 기록 생성 (STARTED)
        ↓
[트랜잭션 밖] esimProvider.order(
                  packageCode = plan.providerPackageCode,
                  reference   = order.orderNo )
        ↓ 성공                                   ↓ 실패 (예외)
ProvisionedEsim                                  EsimProviderException(reason)
 { iccid, smdpAddress, matchingId,
   providerOrderId }
        ↓                                        ↓
[트랜잭션 2]                                     [트랜잭션 2]
 Esim.issue(...) 저장 (ISSUED)                    attempt = FAILED(reason)
 attempt = SUCCEEDED                             order.markFulfillmentFailed()
 order.markFulfilled()
```

### 가짜 공급사 동작

```text
FakeEsimProvider.order(packageCode, reference)
        ↓
설정 esim.fake.mode 확인
  success (기본) → 임의 ICCID(89로 시작하는 19자리),
                   smdpAddress = "smdp.fake.esimtravel.test",
                   matchingId  = 임의 영숫자 → ProvisionedEsim 반환
  fail           → EsimProviderException(PROVIDER_ERROR)
  out-of-stock   → EsimProviderException(OUT_OF_STOCK)
  timeout        → 잠깐 기다린 뒤 EsimProviderException(TIMEOUT)
```

가짜 활성화 코드는 실제 폰에 설치되지 않는다. 형식만 진짜와 같다.

## Key Decisions

| 결정 | 선택 | 고려한 다른 방법 |
|------|------|-----------------|
| 발급 호출 방식 | 결제 승인 요청 안에서 동기 호출 | `@Async`, 메시지 큐는 더 견고하지만 초보자에게 어려움. MVP 이후 검토 |
| 구현체 선택 | `@ConditionalOnProperty(name = "esim.provider", havingValue = "fake", matchIfMissing = true)` | `@Profile`도 가능. 프로퍼티가 더 명시적 |
| 중복 발급 방지 | `esims.order_id` UNIQUE + 사전 확인 | 사전 확인만으로는 동시 요청을 못 막음 |
| 활성화 코드 저장 | SM-DP+ 주소와 매칭 ID를 따로 저장하고, LPA 문자열은 필요할 때 조립 | 통째로 저장해도 되지만 나눠 두면 Android 수동 입력 안내에 바로 씀 |
| 발급 결과가 결제 응답에 주는 영향 | 발급이 실패해도 결제 승인 응답은 200 (`status: FULFILLMENT_FAILED`) | 결제는 성공했으므로 에러로 응답하면 사용자가 다시 결제하려 함 |

## Project Structure

```text
backend/src/main/java/com/esimtravel/esim/
├── controller/EsimIssueController.java        (재시도 API)
├── service/EsimIssueService.java
├── domain/Esim.java, EsimStatus.java, EsimIssueAttempt.java
├── repository/EsimRepository.java, EsimIssueAttemptRepository.java
└── provider/
    ├── EsimProvider.java                      (interface)
    ├── ProvisionedEsim.java                   (record)
    ├── EsimProviderException.java, FailureReason.java
    └── fake/FakeEsimProvider.java
```
