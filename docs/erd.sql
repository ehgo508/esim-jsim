-- 이심전심 ERD (ERDCloud에서 내보낸 SQL, 2026-11-25)
-- 설계 확인용이다. AUTO_INCREMENT, UNIQUE, INDEX는 COMMENT에만 적혀 있어 이 파일을 실행해도 걸리지 않는다.
-- 컬럼 정의의 기준은 specs/*/data-model.md 이다.

CREATE TABLE `plans` (
	`id`	BIGINT	NOT NULL	COMMENT 'AUTO_INCREMENT',
	`country_id`	BIGINT	NOT NULL	COMMENT 'INDEX (country_id, status, price_krw)',
	`name`	VARCHAR(100)	NOT NULL	COMMENT '예: 일본 5일 3GB',
	`data_mb`	INT	NULL	COMMENT 'MB 단위 (예: 3072). 무제한이면 NULL',
	`unlimited`	BOOLEAN	NOT NULL,
	`validity_days`	INT	NOT NULL	COMMENT '일 단위 (예: 5)',
	`price_krw`	BIGINT	NOT NULL	COMMENT '원 단위, 부가세 포함 (예: 9900)',
	`voice_minutes`	INT	NULL	COMMENT '분 단위. 통화 포함 시에만',
	`sms_count`	INT	NULL	COMMENT '건수. 문자 포함 시에만',
	`status`	VARCHAR(20)	NOT NULL	COMMENT 'ON_SALE, STOPPED',
	`provider_package_code`	VARCHAR(100)	NOT NULL	COMMENT '공급사 상품 코드 (응답에 노출 금지)',
	`created_at`	DATETIME(6)	NOT NULL,
	`updated_at`	DATETIME(6)	NOT NULL
);

CREATE TABLE `payments` (
	`id`	BIGINT	NOT NULL	COMMENT 'AUTO_INCREMENT',
	`order_id`	BIGINT	NOT NULL	COMMENT 'UNIQUE, 주문당 결제 1건',
	`payment_key`	VARCHAR(200)	NULL	COMMENT 'UNIQUE, 토스 결제 키',
	`method`	VARCHAR(30)	NULL	COMMENT '카드, 간편결제 등',
	`approved_amount_krw`	BIGINT	NULL,
	`status`	VARCHAR(20)	NOT NULL	COMMENT 'DONE, FAILED',
	`fail_code`	VARCHAR(100)	NULL	COMMENT '토스 실패 코드',
	`fail_message`	VARCHAR(500)	NULL,
	`approved_at`	DATETIME(6)	NULL,
	`created_at`	DATETIME(6)	NOT NULL
);

CREATE TABLE `users` (
	`id`	BIGINT	NOT NULL	COMMENT 'AUTO_INCREMENT',
	`email`	VARCHAR(255)	NOT NULL	COMMENT 'UNIQUE, 소문자로 저장',
	`password_hash`	VARCHAR(100)	NOT NULL	COMMENT 'BCrypt 결과 (60자)',
	`name`	VARCHAR(30)	NOT NULL,
	`status`	VARCHAR(20)	NOT NULL	COMMENT 'ACTIVE',
	`created_at`	DATETIME(6)	NOT NULL,
	`updated_at`	DATETIME(6)	NOT NULL
);

CREATE TABLE `orders` (
	`id`	BIGINT	NOT NULL	COMMENT 'AUTO_INCREMENT',
	`order_no`	VARCHAR(64)	NOT NULL	COMMENT 'UNIQUE, 외부 공개 주문번호',
	`user_id`	BIGINT	NOT NULL	COMMENT 'INDEX (user_id, created_at DESC)',
	`plan_id`	BIGINT	NOT NULL,
	`order_name`	VARCHAR(100)	NOT NULL	COMMENT '주문 시점 요금제 이름 복사',
	`amount_krw`	BIGINT	NOT NULL	COMMENT '주문 시점 가격 복사',
	`status`	VARCHAR(30)	NOT NULL	COMMENT 'CREATED, PAID, FULFILLED, PAYMENT_FAILED, FULFILLMENT_FAILED',
	`paid_at`	DATETIME(6)	NULL,
	`created_at`	DATETIME(6)	NOT NULL,
	`updated_at`	DATETIME(6)	NOT NULL
);

CREATE TABLE `countries` (
	`id`	BIGINT	NOT NULL	COMMENT 'AUTO_INCREMENT',
	`code`	CHAR(2)	NOT NULL	COMMENT 'UNIQUE, ISO 3166-1 alpha-2 (예: JP)',
	`name_ko`	VARCHAR(50)	NOT NULL	COMMENT '예: 일본',
	`flag_emoji`	VARCHAR(10)	NULL	COMMENT '예: 🇯🇵'
);

CREATE TABLE `esims` (
	`id`	BIGINT	NOT NULL	COMMENT 'AUTO_INCREMENT',
	`user_id`	BIGINT	NOT NULL	COMMENT '소유자',
	`order_id`	BIGINT	NOT NULL	COMMENT 'UNIQUE, 주문당 1개',
	`plan_id`	BIGINT	NOT NULL,
	`iccid`	VARCHAR(22)	NOT NULL	COMMENT 'UNIQUE, eSIM 고유 번호',
	`smdp_address`	VARCHAR(255)	NOT NULL,
	`matching_id`	VARCHAR(255)	NOT NULL,
	`status`	VARCHAR(20)	NOT NULL	COMMENT 'ISSUED, INSTALLED, ACTIVE, EXPIRED',
	`provider`	VARCHAR(30)	NOT NULL	COMMENT 'fake, airalo ...',
	`provider_order_id`	VARCHAR(100)	NULL,
	`issued_at`	DATETIME(6)	NOT NULL,
	`created_at`	DATETIME(6)	NOT NULL,
	`updated_at`	DATETIME(6)	NOT NULL,
	`installed_at`	DATETIME(6)	NULL	COMMENT '사용자가 설치 완료를 누른 시각',
	`activated_at`	DATETIME(6)	NULL	COMMENT '현지에서 처음 연결된 시각',
	`expires_at`	DATETIME(6)	NULL	COMMENT '만료 시각'
);

CREATE TABLE `esim_issue_attempts` (
	`id`	BIGINT	NOT NULL	COMMENT 'AUTO_INCREMENT',
	`order_id`	BIGINT	NOT NULL	COMMENT 'UNIQUE: (order_id, attempt_no)',
	`attempt_no`	INT	NOT NULL	COMMENT 'UNIQUE: (order_id, attempt_no)',
	`result`	VARCHAR(20)	NOT NULL	COMMENT 'STARTED, SUCCEEDED, FAILED',
	`failure_reason`	VARCHAR(30)	NULL	COMMENT 'PROVIDER_ERROR, OUT_OF_STOCK, TIMEOUT',
	`failure_detail`	VARCHAR(500)	NULL	COMMENT '공급사 메시지',
	`created_at`	DATETIME(6)	NOT NULL
);

CREATE TABLE `esim_usage_snapshots` (
	`id`	BIGINT	NOT NULL	COMMENT 'AUTO_INCREMENT',
	`esim_id`	BIGINT	NOT NULL	COMMENT 'UNIQUE, eSIM당 1건',
	`data_total_mb`	INT	NULL	COMMENT '무제한이면 NULL',
	`data_used_mb`	INT	NOT NULL,
	`voice_total_min`	INT	NULL	COMMENT '통화 미포함이면 NULL',
	`voice_used_min`	INT	NULL,
	`sms_total`	INT	NULL	COMMENT '문자 미포함이면 NULL',
	`sms_used`	INT	NULL,
	`synced_at`	DATETIME(6)	NOT NULL	COMMENT '공급사에서 가져온 시각'
);

ALTER TABLE `plans` ADD CONSTRAINT `PK_PLANS` PRIMARY KEY (
	`id`
);

ALTER TABLE `payments` ADD CONSTRAINT `PK_PAYMENTS` PRIMARY KEY (
	`id`
);

ALTER TABLE `users` ADD CONSTRAINT `PK_USERS` PRIMARY KEY (
	`id`
);

ALTER TABLE `orders` ADD CONSTRAINT `PK_ORDERS` PRIMARY KEY (
	`id`
);

ALTER TABLE `countries` ADD CONSTRAINT `PK_COUNTRIES` PRIMARY KEY (
	`id`
);

ALTER TABLE `esims` ADD CONSTRAINT `PK_ESIMS` PRIMARY KEY (
	`id`
);

ALTER TABLE `esim_issue_attempts` ADD CONSTRAINT `PK_ESIM_ISSUE_ATTEMPTS` PRIMARY KEY (
	`id`
);

ALTER TABLE `esim_usage_snapshots` ADD CONSTRAINT `PK_ESIM_USAGE_SNAPSHOTS` PRIMARY KEY (
	`id`
);

ALTER TABLE `plans` ADD CONSTRAINT `FK_countries_TO_plans_1` FOREIGN KEY (
	`country_id`
)
REFERENCES `countries` (
	`id`
);

ALTER TABLE `payments` ADD CONSTRAINT `FK_orders_TO_payments_1` FOREIGN KEY (
	`order_id`
)
REFERENCES `orders` (
	`id`
);

ALTER TABLE `orders` ADD CONSTRAINT `FK_users_TO_orders_1` FOREIGN KEY (
	`user_id`
)
REFERENCES `users` (
	`id`
);

ALTER TABLE `orders` ADD CONSTRAINT `FK_plans_TO_orders_1` FOREIGN KEY (
	`plan_id`
)
REFERENCES `plans` (
	`id`
);

ALTER TABLE `esims` ADD CONSTRAINT `FK_users_TO_esims_1` FOREIGN KEY (
	`user_id`
)
REFERENCES `users` (
	`id`
);

ALTER TABLE `esims` ADD CONSTRAINT `FK_orders_TO_esims_1` FOREIGN KEY (
	`order_id`
)
REFERENCES `orders` (
	`id`
);

ALTER TABLE `esims` ADD CONSTRAINT `FK_plans_TO_esims_1` FOREIGN KEY (
	`plan_id`
)
REFERENCES `plans` (
	`id`
);

ALTER TABLE `esim_issue_attempts` ADD CONSTRAINT `FK_orders_TO_esim_issue_attempts_1` FOREIGN KEY (
	`order_id`
)
REFERENCES `orders` (
	`id`
);

ALTER TABLE `esim_usage_snapshots` ADD CONSTRAINT `FK_esims_TO_esim_usage_snapshots_1` FOREIGN KEY (
	`esim_id`
)
REFERENCES `esims` (
	`id`
);
