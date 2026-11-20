# Feature Specification: 내 eSIM 상태와 사용량 조회

**Feature Branch**: `006-my-esim-usage`

**Created**: 2026-11-20

**Status**: Draft

**Input**: User description: "내가 산 eSIM 목록과 상태를 보고, 데이터를 얼마나 썼는지, 통화와 문자가 포함된 요금제면 그것도 얼마나 남았는지 본다."

## Scope

**이 기능이 다루는 것**
- 내 eSIM 목록 (상태, 요금제, 국가)
- eSIM 상세와 사용량 (데이터, 통화, 문자, 남은 기간)
- 공급사에서 사용량과 상태를 가져와 우리 DB에 반영
- 짧은 시간 안의 반복 조회는 저장된 값을 재사용 (공급사 호출 줄이기)

**이 기능이 다루지 않는 것 (MVP 이후)**
- 데이터 부족 알림, 만료 임박 알림
- 데이터 충전
- 사용량 그래프, 일별 내역
- 주기적으로 모든 eSIM을 갱신하는 스케줄러

## Policy Summary

| 항목 | 정책 |
|------|------|
| 조회 권한 | 본인 eSIM만 |
| 데이터 사용량 | 항상 표시. 총량, 사용량, 남은 양 (MB). 무제한 요금제는 사용량만 표시 |
| 통화·문자 | 요금제에 포함된 경우에만 표시. 포함되지 않으면 응답에서 `null` |
| 남은 기간 | 만료 시각이 있으면 "남은 일수" 계산. 아직 개통 전이면 `null`과 "현지에서 처음 연결하면 시작돼요" 안내 |
| 값의 출처 | 폰이 아니라 공급사 서버. 실제 사용보다 몇 분 늦을 수 있음. 응답에 `syncedAt`(마지막 갱신 시각) 포함 |
| 갱신 주기 | 마지막 갱신 후 5분이 안 지났으면 저장된 값을 그대로 응답. 지났으면 공급사에서 다시 가져옴 |
| 공급사 장애 시 | 저장된 마지막 값을 응답하고 `stale = true` 표시. 저장된 값도 없으면 `USAGE-6002` |
| 상태 보정 | 공급사가 알려주는 상태로 eSIM 상태를 갱신 (`INSTALLED` → `ACTIVE` → `EXPIRED`). 상태는 뒤로 돌아가지 않음 |
| 목록 정렬 | 사용 중·설치 전이 위, 만료가 아래. 같은 그룹 안에서는 최신순 |

## User Scenarios & Testing *(mandatory)*

### User Story 1 - 내 eSIM 목록 (Priority: P1)

여행자가 "내 eSIM"에서 산 eSIM들을 상태와 함께 본다.

**Why this priority**: 설치 안내(005)로 들어가는 입구이자 구매 확인 화면이다.

**Independent Test**: eSIM 2개를 가진 사용자로 목록을 조회한다.

**Acceptance Scenarios**:

1. **Given** `ACTIVE` 1개와 `EXPIRED` 1개, **When** 목록을 조회하면, **Then** `ACTIVE`가 위에 나온다.
2. **Given** 다른 사용자의 eSIM, **When** 목록을 조회하면, **Then** 내 것만 나온다.

---

### User Story 2 - 사용량 보기 (Priority: P1)

여행 중인 사용자가 "3GB 중 1.2GB 사용, 4일 남음"을 확인한다.

**Why this priority**: 여행 중 가장 자주 여는 화면이다.

**Independent Test**: 가짜 공급사가 정해진 사용량을 돌려주게 하고 응답 값을 확인한다.

**Acceptance Scenarios**:

1. **Given** 데이터 전용 3GB 요금제에서 1,228MB 사용, **When** 사용량을 조회하면, **Then** total 3072, used 1228, remaining 1844이고 `voice`, `sms`는 `null`이다.
2. **Given** 통화 100분 포함 요금제에서 30분 사용, **When** 조회하면, **Then** `voice`에 total 100, used 30, remaining 70이 나온다.
3. **Given** 아직 개통 전(`ISSUED`), **When** 조회하면, **Then** 사용량 0, `expiresAt = null`과 안내 문구가 나온다.

---

### User Story 3 - 갱신 주기와 장애 대응 (Priority: P2)

화면을 여러 번 새로고침해도 공급사를 매번 부르지 않고, 공급사가 죽어도 마지막 값을 보여준다.

**Why this priority**: 실제 공급사는 호출 횟수 제한이 있다. 가짜 공급사 단계에서는 없어도 동작한다.

**Independent Test**: 5분 안에 두 번 조회해 공급사 호출이 1번인지 확인한다.

**Acceptance Scenarios**:

1. **Given** 1분 전에 갱신됨, **When** 다시 조회하면, **Then** 공급사를 부르지 않고 저장된 값을 응답한다.
2. **Given** 10분 전에 갱신됐고 공급사가 오류, **When** 조회하면, **Then** 저장된 값과 `stale = true`를 응답한다.
3. **Given** 공급사가 "만료됨"을 응답, **When** 조회하면, **Then** eSIM 상태가 `EXPIRED`로 바뀐다.

### Edge Cases

- 사용량이 총량보다 크게 오면 remaining은 0으로 표시한다 (음수 금지).
- 시간 비교는 UTC로 한다. "남은 일수"는 올림(1.2일 남으면 2일)으로 표시한다.
- `EXPIRED` eSIM은 공급사를 다시 부르지 않고 마지막 값을 보여준다.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: 시스템은 본인 eSIM 목록을 상태와 함께 보여줘야 한다.
- **FR-002**: 시스템은 데이터 총량, 사용량, 남은 양을 보여줘야 한다.
- **FR-003**: 시스템은 통화·문자가 포함된 요금제에서만 통화·문자 사용량을 보여줘야 한다.
- **FR-004**: 시스템은 사용량이 마지막으로 갱신된 시각을 함께 보여줘야 한다.
- **FR-005**: 시스템은 5분 안의 재조회에서 공급사를 다시 부르지 않아야 한다.
- **FR-006**: 시스템은 공급사 장애 시 마지막 저장 값을 보여줘야 한다.
- **FR-007**: 시스템은 공급사가 알려주는 상태로 eSIM 상태를 갱신하되, 뒤로 되돌리지 않아야 한다.

### Key Entities

- **Esim** (004): 상태 갱신 대상. `activatedAt`, `expiresAt` 추가.
- **EsimUsageSnapshot**: eSIM당 1건의 마지막 사용량. 데이터·통화·문자 총량과 사용량, 갱신 시각.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: 사용자가 로그인 후 탭 2번 이하로 남은 데이터를 확인한다.
- **SC-002**: 1분에 10번 새로고침해도 공급사 호출은 1번이다.
- **SC-003**: 공급사 장애 중에도 사용량 화면이 에러 없이 열린다 (이전에 한 번이라도 조회한 경우).

## Assumptions

- 가짜 공급사는 발급 후 흐른 시간에 비례해 사용량이 늘어나는 것처럼 값을 만들어 준다 (화면 확인용).
- 실제 공급사의 사용량 API는 호출 제한과 지연이 있다. Airalo의 사용량 API는 데이터, 문자, 통화를 함께 돌려준다. 연동 시 공급사 문서로 필드를 다시 확인한다.
