const express = require("express");
const cors = require("cors");
const dotenv = require("dotenv");
const path = require("path");

const connectDB = require("./config/db");
const authRoutes = require("./routes/authRoutes");
const userRoutes = require("./routes/userRoutes");
const postRoutes = require("./routes/postRoutes");
const uploadRoutes = require("./routes/uploadRoutes");
const { errorHandler, notFoundHandler } = require("./middlewares/errorMiddleware");

const http = require("http");
const { Server } = require("socket.io");
const { initSocketIO } = require("./socket/roomManager");

const messageRoutes = require("./routes/messageRoutes");

dotenv.config();
connectDB();

const app = express();

app.use(cors());
app.use(express.json());

// Serve uploaded files as static assets
app.use("/uploads", express.static(path.join(__dirname, "uploads")));

app.get("/", (req, res) => {
  return res.status(200).json({
    success: true,
    message: "Social Board Game Management API is running",
    data: {},
  });
});

app.use("/auth", authRoutes);
app.use("/users", userRoutes);
app.use("/posts", postRoutes);
app.use("/messages", messageRoutes);
app.use("/upload", uploadRoutes);

app.use(notFoundHandler);
app.use(errorHandler);

const PORT = process.env.PORT || 5000;

// Create HTTP server
const server = http.createServer(app);

// Initialize Socket.IO
const io = new Server(server, {
  cors: {
    origin: "*",
    methods: ["GET", "POST"]
  }
});

// Start socket manager
initSocketIO(io);
app.set("io", io);

server.listen(PORT, () => {
  // eslint-disable-next-line no-console
  console.log(`Server running on port ${PORT}`);
});
