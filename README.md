# Database-SQLServer

## Nhật ký SQL/ERD — Billing, 2026-10-27

Đồng bộ `BillingDb.sql` với chức năng quản lý quầy và lập/tra cứu hóa đơn của backend.

| Bảng | Thay đổi | Default | Khóa và quan hệ |
| --- | --- | --- | --- |
| CashRegister | Thêm `RestaurantId uniqueidentifier NOT NULL` | Không có | Restaurant 1–n CashRegister là quan hệ logic; không tạo FK xuyên database |
| Bill | Thêm `RestaurantId uniqueidentifier NOT NULL` | Không có | Restaurant 1–n Bill là quan hệ logic; không tạo FK xuyên database |
| BillLine | Đổi `CogsSnapshot decimal(18,2) NOT NULL` thành `decimal(18,2) NULL` | Không có | Không thay đổi PK/FK hoặc dây nối ERD |

Không thêm bảng, UNIQUE, CHECK hoặc index. `OriginalTableRef` đã tồn tại, không thêm cột này. Giá vốn chưa xác định được lưu NULL, không coi là 0.

Đã kiểm thử phần CREATE TABLE trên SQL Server trong database tạm riêng: đủ 22 bảng, đúng ba định nghĩa cột và không có FK cho RestaurantId. Không chạy phần DROP DATABASE của file lên database đang sử dụng.

`BillingDb.sql` vẫn là script khởi tạo lại database và có lệnh xóa dữ liệu ở đầu file. Với database đang có dữ liệu, dùng các script nâng cấp `BillingCashRegisterRestaurant.sql` và `BillingBillRestaurant.sql` trong thư mục `docker/sql/upgrades` của repo backend. Bill/quầy cũ chưa có ánh xạ chi nhánh phải được xử lý rõ ràng; không tự gán một chi nhánh mặc định.

## Nhật ký SQL/ERD — Checkout, 2026-10-28

Bổ sung đúng hai bảng mới để giữ lượt checkout và chặn gọi thêm món theo toàn bộ phiên bàn. Không sửa cột, dữ liệu hoặc ràng buộc của bảng cũ.

| Database/bảng mới | Cột | Kiểu dữ liệu | NULL | DEFAULT |
| --- | --- | --- | --- | --- |
| BillingDb.BillCheckout | CheckoutId | uniqueidentifier | NOT NULL | Không |
| BillingDb.BillCheckout | BillId | uniqueidentifier | NULL | Không |
| BillingDb.BillCheckout | TableSessionRef | uniqueidentifier | NOT NULL | Không |
| BillingDb.BillCheckout | SourceHash | char(64) | NULL | Không |
| BillingDb.BillCheckout | Status | varchar(20) | NOT NULL | Không |
| BillingDb.BillCheckout | CreatedAt | datetime2(7) | NOT NULL | Không |
| BillingDb.BillCheckout | ReleasedAt | datetime2(7) | NULL | Không |
| OrderingDb.CheckoutLock | CheckoutId | uniqueidentifier | NOT NULL | Không |
| OrderingDb.CheckoutLock | BillIdRef | uniqueidentifier | NULL | Không |
| OrderingDb.CheckoutLock | TableSessionRef | uniqueidentifier | NOT NULL | Không |
| OrderingDb.CheckoutLock | SourceHash | char(64) | NULL | Không |
| OrderingDb.CheckoutLock | Status | varchar(20) | NOT NULL | Không |
| OrderingDb.CheckoutLock | CreatedAt | datetime2(7) | NOT NULL | Không |
| OrderingDb.CheckoutLock | ReleasedAt | datetime2(7) | NULL | Không |

Khóa/index và dây nối ERD:

- PK_BillCheckout(CheckoutId) và PK_CheckoutLock(CheckoutId).
- FK_BillCheckout_Bill: BillCheckout.BillId → Bill.BillId, nội bộ BillingDb, không cascade delete. Bill 1–n BillCheckout; mỗi checkout có thể chưa có bill (0..1).
- UX_BillCheckout_ActiveSession và UX_CheckoutLock_ActiveSession: UNIQUE trên TableSessionRef, WHERE ReleasedAt IS NULL. Mỗi phiên chỉ có một lượt chưa mở lại gọi món tại mỗi service.
- TableSession 1–n BillCheckout và TableSession 1–n CheckoutLock: quan hệ logic xuyên service qua TableSessionRef, không FK.
- Bill 1–n CheckoutLock: quan hệ logic qua BillIdRef (nullable), không FK xuyên database.
- CheckoutId đối chiếu cùng lượt giữa hai bảng là quan hệ logic tối đa 1–1; Ordering có thể chưa có bản ghi khi Billing còn Preparing.
- Không thêm CHECK hoặc DEFAULT. SourceHash/BillId có thể NULL khi chờ xử lý, không điền hash hoặc ID giả.

CreatedAt/ReleasedAt được backend ghi theo UTC. ReleasedAt chỉ thể hiện đã mở lại gọi món sau xác nhận của Ordering; không đồng nghĩa đã thanh toán hoặc đóng phiên. Thanh toán thành công không được vô tình giải phóng khóa gọi món.

Hai file SQL ở đây vẫn là script khởi tạo lại database, có DROP DATABASE ở đầu. Không chạy toàn bộ lên database đang có dữ liệu. Với database hiện có, dùng BillingCheckout.sql và OrderingCheckout.sql trong docker/sql/upgrades của repository backend; các script này có transaction, kiểm tra metadata và không xóa dữ liệu cũ.

Nguồn đồng bộ: phần DDL checkout trong docker/sql/schema/BillingDb.sql và docker/sql/schema/OrderingDb.sql của backend. Chỉ đồng bộ hai bảng checkout, không chép đè các bảng cũ hoặc đồng bộ Catalog/Restaurant/Identity.

Đã kiểm thử phần CREATE-only trên SQL Server thật bằng hai database tạm riêng: Billing có 23 bảng, Ordering có 13 bảng; mỗi bảng checkout có đúng 7 cột, timestamp datetime2(7), hash nullable, PK/index đúng và không có DEFAULT. BillCheckout có một FK nội bộ Bill; CheckoutLock không có FK. Hai database tạm đã được dọn sau khi kiểm tra; không chạy phần reset lên BillingDb/OrderingDb đang sử dụng.
