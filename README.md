# 🎮 Sân Chơi Board Game Xã Hội

Nền tảng trò chơi xã hội đa nền tảng được xây dựng bằng **Flutter** (frontend) và **Node.js/Express + MongoDB** (backend). Giao diện theo phong cách **NebulaPlay** — dark mode, glassmorphism, hiệu ứng động mượt mà.

---

## 📸 Tính năng chính

- 🔐 **Đăng ký / Đăng nhập** — Xác thực JWT an toàn
- 🎲 **Phòng trò chơi** — Ma Sói, Vẽ và Đoán, Đấu Nhạc, Uno Online
- 🧩 **Sliding Puzzle** — Mini-game xếp hình trượt (3×3 & 4×4)
- 👥 **Mạng xã hội** — Trang Social, tìm bạn bè
- 👤 **Hồ sơ cá nhân** — Quản lý thông tin người dùng
- 🛡️ **Admin Dashboard** — Bảng điều khiển quản trị

---

## 🛠️ Công nghệ sử dụng

| Thành phần | Công nghệ |
|-----------|-----------|
| Frontend  | Flutter (Dart) `sdk ^3.11.4` |
| Backend   | Node.js, Express 5, Mongoose |
| Database  | MongoDB |
| Auth      | JWT (jsonwebtoken + bcryptjs) |
| State     | Provider |
| HTTP      | `http` package |
| Storage   | `shared_preferences` |

---

## 📁 Cấu trúc thư mục

```
mobile_app/
├── lib/
│   ├── main.dart                 # Entry point
│   ├── models/
│   │   └── user_model.dart       # Model người dùng
│   ├── providers/
│   │   ├── auth_provider.dart    # Quản lý xác thực
│   │   └── user_provider.dart    # Quản lý thông tin user
│   ├── services/
│   │   ├── api_client.dart       # HTTP client chung
│   │   ├── app_config.dart       # Cấu hình API URL
│   │   ├── auth_service.dart     # Gọi API đăng nhập/đăng ký
│   │   ├── token_storage.dart    # Lưu trữ JWT token
│   │   └── user_service.dart     # Gọi API thông tin user
│   ├── screens/
│   │   ├── login_screen.dart
│   │   ├── register_screen.dart
│   │   ├── nebula_shell_screen.dart   # Bottom navigation shell
│   │   ├── nebula_games_screen.dart   # Danh sách trò chơi
│   │   ├── nebula_social_screen.dart  # Mạng xã hội
│   │   ├── nebula_room_screen.dart    # Phòng chơi game
│   │   ├── nebula_profile_screen.dart # Hồ sơ cá nhân
│   │   ├── sliding_puzzle_screen.dart # Màn hình Sliding Puzzle
│   │   ├── lobby_screen.dart
│   │   └── admin_dashboard_screen.dart
│   ├── games/
│   │   └── sliding_puzzle/
│   │       ├── sliding_puzzle_game.dart  # Widget chính (SlidingPuzzleGame)
│   │       ├── puzzle_controller.dart    # Logic game + solvability
│   │       ├── puzzle_board.dart         # Board layout (Stack)
│   │       └── puzzle_tile.dart          # Tile animation
│   └── widgets/
│       └── nebula_theme.dart     # Design system (màu sắc, glass effect)
├── backend/
│   ├── server.js                 # Express server entry point
│   ├── config/                   # Cấu hình DB
│   ├── controllers/              # Xử lý request
│   ├── middlewares/              # Auth middleware
│   ├── models/                   # Mongoose schemas
│   ├── routes/                   # API routes
│   ├── utils/                    # Hàm tiện ích
│   ├── .env.example              # Mẫu biến môi trường
│   └── package.json
├── android/                      # Android platform
├── web/                          # Web platform
├── test/                         # Unit tests
└── pubspec.yaml                  # Flutter dependencies
```

---

## ⚙️ Yêu cầu hệ thống

| Phần mềm | Phiên bản tối thiểu |
|-----------|---------------------|
| [Flutter SDK](https://docs.flutter.dev/get-started/install) | `>= 3.11.4` |
| [Dart SDK](https://dart.dev/get-dart) | Đi kèm Flutter |
| [Node.js](https://nodejs.org/) | `>= 18.x` |
| [MongoDB Atlas](https://www.mongodb.com/atlas/database) | Free cluster |
| [Git](https://git-scm.com/) | Bất kỳ |

---

## 🚀 Hướng dẫn cài đặt

### 1. Clone dự án

```bash
git clone <repository-url>
cd mobile_app
```

### 2. Cài đặt Backend

```bash
# Di chuyển vào thư mục backend
cd backend

# Cài đặt dependencies
npm install

# Tạo file .env từ mẫu
cp .env.example .env
```

Chỉnh sửa file `backend/.env` theo cấu hình của bạn:

```env
PORT=5000
MONGODB_URI=mongodb+srv://<username>:<password>@<cluster-url>/social_board_game?retryWrites=true&w=majority
DNS_SERVERS=1.1.1.1,8.8.8.8
JWT_SECRET=thay_bang_chuoi_bi_mat_manh
JWT_EXPIRES_IN=7d
```

Thiết lập MongoDB Atlas:

1. Tạo free cluster trên MongoDB Atlas.
2. Tạo database user trong **Database Access**.
3. Thêm IP của bạn trong **Network Access**. Khi phát triển, có thể allow current IP.
4. Vào **Connect > Drivers**, copy connection string dạng `mongodb+srv://...`, rồi dán vào `backend/.env`.
5. Thay `<password>` bằng mật khẩu database user. Nếu mật khẩu có ký tự đặc biệt, hãy URL-encode mật khẩu.

Khi `MONGODB_URI` trỏ tới Atlas, bạn không cần chạy MongoDB local.

Nếu gặp lỗi `querySrv ECONNREFUSED _mongodb._tcp...`, giữ dòng `DNS_SERVERS=1.1.1.1,8.8.8.8` để Node.js resolve được connection string `mongodb+srv://`.

### 3. Cài đặt Frontend (Flutter)

```bash
# Quay về thư mục gốc
cd ..

# Tải Flutter dependencies
flutter pub get
```

### 4. Cấu hình API URL

Mở file `lib/services/app_config.dart` và cập nhật địa chỉ API phù hợp:

- **Android Emulator:** `http://10.0.2.2:5000/api`
- **iOS Simulator / Web:** `http://localhost:5000/api`
- **Thiết bị thật:** `http://<ip-máy-tính>:5000/api`

---

## ▶️ Hướng dẫn chạy

### Bước 1 — Kiểm tra MongoDB Atlas

Đảm bảo cluster Atlas đang hoạt động, IP của bạn đã được allow trong **Network Access**, và `backend/.env` đã có `MONGODB_URI=mongodb+srv://...`.

### Bước 2 — Khởi tạo tài khoản admin

Chạy seed admin sau khi `backend/.env` đã kết nối được MongoDB Atlas. Lệnh này chỉ tạo admin nếu email chưa tồn tại.

```bash
cd backend
npm run seed:admin
```

Tài khoản admin mặc định:

```text
Email: admin@admin.com
Password: admin123
```

Sau khi đăng nhập lần đầu, nên đổi mật khẩu admin hoặc chỉnh thông tin mặc định trong `backend/seedAdmin.js` trước khi seed dữ liệu thật.

### Bước 3 — Khởi động Backend

```bash
cd backend

# Chế độ development (tự reload khi thay đổi code)
npm run dev

# Hoặc chế độ production
npm start
```

> Server sẽ chạy tại `http://localhost:5000`

### Bước 4 — Chạy ứng dụng Flutter

```bash
# Quay về thư mục gốc
cd ..

# Kiểm tra thiết bị có sẵn
flutter devices

# Chạy trên Chrome (Web)
flutter run -d chrome

# Chạy trên Android Emulator
flutter run -d emulator

# Chạy trên thiết bị Android kết nối USB
flutter run -d <device-id>

# Chạy trên tất cả thiết bị
flutter run -d all
```

---

## 🧩 Mini-Game: Sliding Puzzle

Widget `SlidingPuzzleGame()` có thể được nhúng vào bất kỳ màn hình nào:

```dart
import 'package:mobile_app/games/sliding_puzzle/sliding_puzzle_game.dart';

// Sử dụng trực tiếp
const SlidingPuzzleGame()

// Hoặc mở màn hình riêng
Navigator.push(
  context,
  MaterialPageRoute(builder: (_) => const SlidingPuzzleScreen()),
);
```

**Tính năng:**
- Hỗ trợ chế độ 3×3 (Easy) và 4×4 (Hard)
- Thuật toán đảm bảo luôn giải được (inversion parity)
- Đếm số bước + bộ đếm thời gian
- Animation mượt mà 250ms
- Hộp thoại chiến thắng với thống kê

---

## 📦 Build Production

```bash
# Build APK cho Android
flutter build apk --release

# Build App Bundle cho Google Play
flutter build appbundle --release

# Build cho Web
flutter build web --release
```

File output:
- APK: `build/app/outputs/flutter-apk/app-release.apk`
- Web: `build/web/`

---

## 🔧 Các lệnh hữu ích

```bash
# Kiểm tra môi trường Flutter
flutter doctor

# Phân tích code (lint)
flutter analyze

# Chạy unit tests
flutter test

# Cập nhật dependencies
flutter pub upgrade

# Dọn dẹp build cache
flutter clean && flutter pub get
```

---

## 👥 Đóng góp

1. Fork dự án
2. Tạo branch tính năng: `git checkout -b feature/ten-tinh-nang`
3. Commit: `git commit -m "feat: mô tả tính năng"`
4. Push: `git push origin feature/ten-tinh-nang`
5. Tạo Pull Request

---

## 📄 License

Dự án này được phát triển cho mục đích học tập.
