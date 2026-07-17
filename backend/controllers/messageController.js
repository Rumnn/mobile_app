const Message = require("../models/Message");

// Get list of conversations with last message & unread count
const getConversations = async (req, res) => {
  try {
    const currentUserId = req.user._id;

    // Find all messages involving the current user
    const messages = await Message.find({
      $or: [{ sender: currentUserId }, { receiver: currentUserId }],
    })
      .sort({ createdAt: -1 })
      .populate("sender", "_id username avatarURL")
      .populate("receiver", "_id username avatarURL");

    const conversationsMap = {};

    for (const msg of messages) {
      if (!msg.sender || !msg.receiver) continue;

      const otherUser = msg.sender._id.toString() === currentUserId.toString()
        ? msg.receiver
        : msg.sender;

      if (!otherUser) continue;

      const otherUserIdStr = otherUser._id.toString();

      if (!conversationsMap[otherUserIdStr]) {
        const isUnread = !msg.read && msg.receiver._id.toString() === currentUserId.toString();
        conversationsMap[otherUserIdStr] = {
          user: {
            _id: otherUser._id,
            username: otherUser.username,
            avatarURL: otherUser.avatarURL,
          },
          lastMessage: msg.content,
          time: msg.createdAt,
          unread: isUnread ? 1 : 0,
        };
      } else {
        if (!msg.read && msg.receiver._id.toString() === currentUserId.toString()) {
          conversationsMap[otherUserIdStr].unread += 1;
        }
      }
    }

    const conversations = Object.values(conversationsMap).sort(
      (a, b) => new Date(b.time) - new Date(a.time)
    );

    return res.status(200).json({
      success: true,
      data: conversations,
    });
  } catch (error) {
    return res.status(500).json({
      success: false,
      message: error.message,
    });
  }
};

// Get direct messages history with a user
const getMessagesWithUser = async (req, res) => {
  try {
    const currentUserId = req.user._id;
    const otherUserId = req.params.userId;

    const messages = await Message.find({
      $or: [
        { sender: currentUserId, receiver: otherUserId },
        { sender: otherUserId, receiver: currentUserId },
      ],
    })
      .sort({ createdAt: 1 })
      .populate("sender", "_id username avatarURL")
      .populate("receiver", "_id username avatarURL");

    return res.status(200).json({
      success: true,
      data: messages,
    });
  } catch (error) {
    return res.status(500).json({
      success: false,
      message: error.message,
    });
  }
};

// Mark conversation messages as read
const markAsRead = async (req, res) => {
  try {
    const currentUserId = req.user._id;
    const otherUserId = req.params.userId;

    await Message.updateMany(
      { sender: otherUserId, receiver: currentUserId, read: false },
      { $set: { read: true } }
    );

    return res.status(200).json({
      success: true,
      message: "Messages marked as read",
    });
  } catch (error) {
    return res.status(500).json({
      success: false,
      message: error.message,
    });
  }
};

module.exports = {
  getConversations,
  getMessagesWithUser,
  markAsRead,
};
