# 5장. eSIM 설치 안내 (005)

## 1. 이 기능에서 배우는 것

이 프로젝트의 출발점인 "왜 설치가 복잡한가"의 기술적 답, 그리고 그 제약 안에서 가장 짧은 설치 경로를 만드는 방법. 코드 면에서는 Spring 없이 테스트할 수 있는 순수 로직을 분리하는 연습이다.

## 2. 알아야 할 개념

### 플랫폼이 허용하는 것과 막는 것

| 개념 | 설명 | 왜 필요한가 |
|------|------|------------|
| 왜 막혀 있는가 | eSIM 설치와 회선 전환은 요금과 통신 감청에 직결된다. 악성 앱이 몰래 회선을 바꾸면 안 되므로 OS가 통신사와 승인된 앱에만 허용한다 | "왜 아직 자동 연결 서비스가 없는가"의 답 |
| iOS `CTCellularPlanProvisioning` | 앱 안에서 eSIM을 추가하는 API. Apple이 통신사 등에 주는 특수 권한(entitlement)이 있어야 동작한다 | 일반 개발자 앱에서는 쓸 수 없다 |
| iOS 유니버설 링크 설치 | iOS 17.4부터 `https://esimsetup.apple.com/esim_qrcode_provisioning?carddata=<LPA 문자열>` 링크를 누르면 시스템 설치 화면이 열린다. 특수 권한이 필요 없다 | 우리 서비스의 핵심 수단 |
| Android `EuiccManager` | eSIM 다운로드 API. `WRITE_EMBEDDED_SUBSCRIPTIONS`(시스템 권한) 또는 해당 프로파일의 통신사 권한(carrier privileges)이 필요 | 일반 앱은 직접 설치 불가 |
| 통신사 권한 | 프로파일 안에 "이 서명의 앱은 이 프로파일을 관리해도 된다"고 적혀 있는 것 | 공급사와 계약하면 받을 수도 있는 권한. MVP 이후 과제 |
| 사용자 동의 | 어떤 방법이든 마지막에는 사용자가 시스템 화면에서 "계속"을 눌러야 한다 | 완전 자동은 불가능 |
| 데이터 로밍, 데이터 회선 선택 | 설치 후에도 여행용 회선을 데이터용으로 고르고 로밍을 켜야 인터넷이 된다 | "현지 도착 후 할 일" 안내 |

### 웹 기술

| 개념 | 설명 | 왜 필요한가 |
|------|------|------------|
| User-Agent | 브라우저가 요청마다 보내는 자기소개 문자열. 기기와 OS 버전이 들어 있다 | 기기 판별 |
| User-Agent의 한계 | 위조 가능하고, iPad가 Mac인 척하기도 한다 | 보안 판단에 쓰지 말고 편의 기능에만 |
| URL 인코딩 | URL에 쓸 수 없는 문자를 `%XX`로 바꾸는 것. `$`는 `%24` | 활성화 코드를 링크에 넣기 |
| 유니버설 링크 / 앱 링크 | 특정 https 주소를 누르면 브라우저 대신 앱이나 시스템 화면이 열리는 기능 | 원탭 설치의 원리 |
| QR 코드 | 문자열을 그림으로 표현한 것. 내용물은 그냥 글자 | 서버는 문자열만 주면 된다 |
| `Cache-Control: no-store` | 응답을 저장하지 말라는 헤더 | 활성화 코드가 캐시에 남지 않게 |
| 클립보드 API | `navigator.clipboard.writeText()` | 코드 복사 버튼 |

### 코드 설계

| 개념 | 설명 |
|------|------|
| 순수 함수 | 입력만으로 출력이 정해지고 외부 상태를 바꾸지 않는 함수. 테스트가 가장 쉽다 |
| 단위 테스트 | 클래스 하나를 Spring 없이 테스트. 수 밀리초에 끝난다 |
| `@ParameterizedTest` | 같은 테스트를 여러 입력으로 반복 |
| 소유권 확인 | `findByIdAndUserId`처럼 "내 것인지"를 조회 조건에 넣는 방법 |

## 3. 공부할 문서

| 주제 | 문서 |
|------|------|
| iPhone eSIM 설정 방법 | Apple 지원 "iPhone에서 eSIM 설정하기" https://support.apple.com/HT212780 (링크를 통한 활성화 항목 포함) |
| iOS 앱 내 설치 API | Apple Developer 문서 "CTCellularPlanProvisioning" https://developer.apple.com/documentation/coretelephony |
| 유니버설 링크 설치 설명 | eSIM Access 블로그 https://esimaccess.com/new-apple-universal-link-for-esim-install/ |
| Android eSIM API와 권한 | Android Open Source Project "eUICC APIs" https://source.android.com/docs/core/connect/esim-euicc-api |
| Android eSIM 개요 | https://source.android.com/docs/core/connect/esim-overview |
| User-Agent | MDN "User-Agent" https://developer.mozilla.org/ko/docs/Web/HTTP/Headers/User-Agent |
| URL 인코딩 | MDN "퍼센트 인코딩" |
| 파라미터 테스트 | JUnit 5 User Guide의 "Parameterized Tests" https://junit.org/junit5/docs/current/user-guide/ |

검색 키워드: `iOS 17.4 eSIM universal link`, `Android carrier privileges eSIM`, `iPhone User-Agent 예시`, `Java URLEncoder UTF-8`, `ResponseEntity 헤더 추가`

실습 과제: 내 폰과 주변 사람 폰 한두 대에서 설정 앱을 열어 eSIM 추가 화면까지 가는 경로를 적어 본다. 기종마다 메뉴 이름이 얼마나 다른지 확인하고, 안내 문구에 반영한다.

## 4. 구현 순서와 힌트

| 작업 | 힌트 |
|------|------|
| T002 DeviceDetector | 실제 User-Agent 문자열을 몇 개 모아 테스트 입력으로 쓴다. 브라우저 개발자 도구에서 볼 수 있다. null과 빈 문자열을 잊지 않는다 |
| T003 iOS 버전 | iPhone의 User-Agent에는 `OS 17_4_1 like Mac OS X` 같은 부분이 있다. 정규식으로 주 버전과 부 버전을 꺼낸다. "17.4 이상" 비교는 문자열이 아니라 숫자 두 개로 한다 (`17.10`이 `17.4`보다 큰지 생각해 본다) |
| T004 링크 조립 | 인코딩 결과에서 `$`가 `%24`인지, 공백이 `+`로 바뀌는 일은 없는지 테스트한다 |
| T005 Factory | 입력(기기, 버전, eSIM)과 출력(추천 방법)의 표를 먼저 그리고 그 표를 그대로 `@ParameterizedTest`로 옮긴다 |
| T007 조회 API | 남의 eSIM은 403이 아니라 404로 응답한다. 왜 그런지 생각해 본다 |
| T011 헤더 테스트 | MockMvc의 `header().string("Cache-Control", ...)`으로 확인한다 |
| T016 실기기 확인 | 로컬 서버를 폰에서 열려면 같은 와이파이에서 PC의 IP로 접속하거나 터널 도구를 쓴다. 가짜 코드라 iOS가 설치를 거부하는 것까지 보면 성공이다 |

## 5. 스스로 점검할 질문

- 일반 앱이 사용자 몰래 eSIM을 설치하고 회선을 바꿀 수 있다면 어떤 악용이 가능한가?
- 그렇다면 "구매하면 자동 연결"에 가장 가까이 갈 수 있는 방법은 무엇이고, 사용자가 꼭 눌러야 하는 단계는 몇 개인가?
- iOS 유니버설 링크 방식이 QR 방식보다 좋은 점을 "기기 수" 관점에서 설명해 보라.
- 나중에 네이티브 앱을 만들면 무엇이 더 좋아지고, 무엇은 여전히 안 되는가?
- User-Agent로 기기를 판별한 결과를 보안 판단(예: 결제 허용)에 쓰면 안 되는 이유는?
- 활성화 코드를 URL에 넣는 것의 위험은 무엇인가? 우리는 어떻게 줄였는가? (이 링크가 우리 서버를 거치는지 생각해 본다)
- 남의 eSIM을 조회했을 때 403 대신 404를 주는 이유는?
- QR 이미지를 서버에서 만들어 URL로 제공하면 어떤 점이 걱정되는가?

## 6. 흔한 실수

- 버전을 문자열로 비교한다 (`"17.10" < "17.4"`가 참이 된다).
- 활성화 코드를 인코딩하지 않고 링크에 붙인다.
- 원탭 링크를 서버에서 리다이렉트로 처리하려다 유니버설 링크가 동작하지 않는다. 사용자가 직접 누르는 `<a>` 링크여야 한다.
- 안내 문구를 한 기종 기준으로만 쓴다.
