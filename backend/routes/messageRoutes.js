const express = require("express");
const { getConversations, getMessagesWithUser, markAsRead } = require("../controllers/messageController");
const protect = require("../middlewares/authMiddleware");

const router = express.Router();

router.get("/conversations", protect, getConversations);
router.get("/:userId", protect, getMessagesWithUser);
router.put("/:userId/read", protect, markAsRead);

module.exports = router;
