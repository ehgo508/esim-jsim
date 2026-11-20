# eSIM 시장·기술 조사 메모 (2026-11-20)

## 시장
- 여행 eSIM 시장: 2025년 약 5.85억 달러, 2032년 18.5억 달러 전망, 연 17.9% 성장 (Research and Markets, 2026-01) https://www.globenewswire.com/news-release/2026/01/21/3222605/0/en/Travel-eSIM-Market-Skyrockets-Expected-to-Reach-1-85-Billion-by-2032.html
- 주요 업체: Airalo(2025년 2.2억 달러 투자, 유니콘), Holafly(누적 1,500만 개, 2024 매출 약 2억 달러), Saily(NordVPN), Nomad, Truely, Ubigi/Transatel, Yesim 등
- eSIM 사용자 51%가 여행용. 장벽: 개념 이해 부족, QR이 이메일로 와서 두 번째 기기가 필요함 (TechCrunch 2025-12-05) https://techcrunch.com/2025/12/05/esim-adoption-is-on-the-rise-thanks-to-travel-and-device-compatibility/

## 기술: 설치 과정
- eSIM 설치 = 활성화 코드(LPA 문자열 `LPA:1$SM-DP+주소$매칭ID`)로 통신사 서버(SM-DP+)에서 프로파일을 내려받는 것. 표준은 GSMA SGP.22.
- iOS: 일반 앱이 직접 설치(CTCellularPlanProvisioning)하려면 Apple이 통신사 등에만 주는 특수 권한(entitlement)이 필요. 공개 문서 없음. https://developer.apple.com/forums/thread/748341 , https://developer.apple.com/forums/thread/773944
- iOS 17.4+: `https://esimsetup.apple.com/esim_qrcode_provisioning?carddata=<LPA문자열>` 링크를 누르면 설치 화면이 바로 열림. 웹에서도 됨. QR 불필요. https://esimaccess.com/new-apple-universal-link-for-esim-install/
- Android: EuiccManager.downloadSubscription은 WRITE_EMBEDDED_SUBSCRIPTIONS(시스템 권한) 또는 해당 프로파일의 통신사 권한(carrier privileges)이 있어야 함. 일반 앱은 불가. 사용자가 설정에서 QR/코드 입력. https://source.android.com/docs/core/connect/esim-euicc-api
- 데이터 회선 전환, 로밍 켜기 같은 설정 변경도 일반 앱은 못 함 (양쪽 OS 공통).

## 공급사 API (리셀러)
- Airalo Partner API: 토큰 인증, 패키지 조회, 주문(동기/비동기), eSIM 조회, 설치 안내, 사용량, 충전, 웹훅, 샌드박스 있음. 파트너 계약 필요. https://developers.partners.airalo.com/
- eSIM Access: 최소 주문량 없음, 가입 무료. https://esimaccess.com/docs/do-i-need-to-sign-a-contract-and-a-moq-to-kickoff/
- eSIM Go: 선불, 최소 충전 1,000달러. https://docs.esim-go.com/guides/setup_esimgo_account/

## 결론 (왜 "자동 연결"이 아직 없나)
1. 판매·발급은 이미 많이 자동화됨 (위 업체들).
2. 마지막 "폰에 설치·전환" 단계는 OS가 통신사에게만 열어줌. 앱으로 만들어도 일반 개발자는 이 권한을 받기 어려움.
3. 대신 iOS는 17.4부터 웹 링크 원탭 설치가 가능해서, 웹만으로도 거의 같은 경험을 만들 수 있음.
