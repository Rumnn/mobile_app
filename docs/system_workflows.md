# Các Luồng Hoạt Động Chính (Sequence Diagrams)

Dựa trên cấu trúc dự án (REST API & Socket.IO), dưới đây là các biểu đồ tuần tự (Sequence Diagram) thể hiện các luồng nghiệp vụ quan trọng nhất của hệ thống Sân Chơi Board Game Xã Hội, được trình bày theo mẫu bạn yêu cầu.

## 1. Luồng Xác thực (Đăng nhập / Đăng ký)
Luồng này xử lý việc người dùng truy cập ứng dụng, gọi API xác thực và lưu trữ JWT token để sử dụng cho các tính năng khác.

```mermaid
sequenceDiagram
    actor User as 👤 Người dùng
    participant App as 📱 Ứng dụng (Flutter)
    participant API as 🌐 REST API (Node.js)
    participant DB as 🗄️ MongoDB

    User->>App: Mở ứng dụng & chọn Đăng nhập
    App->>API: POST /auth/login {email, password}
    API->>DB: Tìm user theo email
    DB-->>API: Trả về dữ liệu user
    API->>API: Kiểm tra hash password (bcrypt)
    alt Sai thông tin
        API-->>App: Trả về lỗi (401 Unauthorized)
        App-->>User: Hiển thị thông báo lỗi
    else Thông tin hợp lệ
        API->>API: Tạo JWT Token
        API-->>App: Trả về Token & Thông tin User (200 OK)
        App->>App: Lưu Token vào Storage (SharedPreferences)
        App-->>User: Chuyển hướng tới màn hình chính (Nebula Shell)
    end
```

## 2. Luồng Phòng Chơi Đa Người Chơi (Multiplayer Room - Socket.IO)
Luồng này sử dụng WebSockets (Socket.IO) để tạo kết nối theo thời gian thực (real-time) giữa những người chơi trong cùng một phòng game (như Ma Sói, Vẽ và Đoán...).

```mermaid
sequenceDiagram
    actor User1 as 👤 Chủ phòng (Host)
    actor User2 as 👤 Người chơi (Guest)
    participant App as 📱 Ứng dụng (Flutter)
    participant Socket as 🔌 Socket.IO Server (Node.js)

    User1->>App: Chọn tính năng "Tạo phòng"
    App->>Socket: Emit sự kiện "create_room" {gameType, settings}
    Socket-->>App: Trả về mã phòng (Room ID)
    App-->>User1: Hiển thị giao diện phòng chờ (Lobby)

    User2->>App: Nhập mã phòng / Chọn tìm phòng
    App->>Socket: Emit sự kiện "join_room" {roomId}
    Socket->>Socket: Kiểm tra số lượng người, trạng thái phòng
    alt Phòng đầy / Đang chơi
        Socket-->>App: Trả về lỗi "Phòng đã đầy"
        App-->>User2: Hiển thị thông báo lỗi
    else Có thể tham gia
        Socket-->>App: Xác nhận tham gia thành công
        App-->>User2: Chuyển vào giao diện phòng chờ
        Socket--)App: Emit "user_joined" tới tất cả người trong phòng
        App-->>User1: Cập nhật danh sách người chơi
    end
    
    User1->>App: Nhấn "Bắt đầu Game"
    App->>Socket: Emit sự kiện "start_game" {roomId}
    Socket--)App: Broadcast "game_started" tới toàn phòng
    App-->>User1: Chuyển sang màn hình chơi game chính thức
    App-->>User2: Chuyển sang màn hình chơi game chính thức
```

## 3. Luồng Mạng Xã Hội và Tin Nhắn
Luồng hoạt động khi người dùng đăng bài viết mới hoặc nhắn tin cá nhân/cộng đồng.

```mermaid
sequenceDiagram
    actor User as 👤 Người dùng
    actor Friend as 👤 Bạn bè
    participant App as 📱 Ứng dụng (Flutter)
    participant API as 🌐 REST API (Node.js)
    participant Socket as 🔌 Socket.IO (Real-time)
    participant DB as 🗄️ MongoDB

    User->>App: Mở chat / Mạng xã hội
    App->>API: GET /posts hoặc /messages
    API->>DB: Truy vấn dữ liệu
    DB-->>API: Trả về dữ liệu
    API-->>App: Danh sách bài viết / tin nhắn
    App-->>User: Hiển thị giao diện xã hội

    User->>App: Gửi tin nhắn mới
    App->>API: POST /messages {receiverId, content} (hoặc qua Socket)
    API->>DB: Lưu tin nhắn mới vào CSDL
    DB-->>API: Xác nhận lưu thành công
    API->>Socket: Kích hoạt sự kiện "new_message" tới người nhận
    Socket--)App (Friend): Push event "new_message" (Real-time)
    App (Friend)-->>Friend: Hiển thị tin nhắn vừa nhận
```

## 4. Luồng Chơi Mini-Game Cục Bộ (Ví dụ: Sliding Puzzle)
Mini-game này hoạt động chủ yếu dựa trên logic ở Client (Flutter) mà không cần gọi API liên tục.

```mermaid
sequenceDiagram
    actor User as 👤 Người dùng
    participant App as 📱 Ứng dụng (Flutter)
    participant Controller as 🧩 Puzzle Controller
    participant API as 🌐 REST API (Tùy chọn lưu kết quả)

    User->>App: Chọn chơi "Sliding Puzzle"
    App->>Controller: Khởi tạo bảng trò chơi (3x3 / 4x4)
    Controller->>Controller: Xáo trộn mảng (Shuffle) đảm bảo giải được
    Controller-->>App: Trả về cấu trúc bảng ban đầu
    App-->>User: Hiển thị bảng game

    loop Quá trình chơi
        User->>App: Chạm vào ô vuông gần ô trống
        App->>Controller: Yêu cầu di chuyển ô (Move Tile)
        Controller->>Controller: Cập nhật vị trí mảng, tăng số bước
        Controller-->>App: Kích hoạt Animation thay đổi vị trí
        App-->>User: Hiển thị sự di chuyển
    end

    Controller->>Controller: Kiểm tra điều kiện thắng (Mảng đã sắp xếp đúng)
    Controller-->>App: Trạng thái "Chiến thắng"
    App-->>User: Hiển thị Popup chiến thắng (Thời gian, Số bước)
    App->>API: (Tùy chọn) POST /users/score {game, score} (Cập nhật thành tích)
```
