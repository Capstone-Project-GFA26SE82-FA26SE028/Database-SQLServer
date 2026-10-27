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
