const express = require("express");
const {
  createPost,
  getPosts,
  getPostById,
  updatePost,
  deletePost,
  toggleLike,
  getComments,
  addComment,
  deleteComment,
} = require("../controllers/postController");
const protect = require("../middlewares/authMiddleware");

const router = express.Router();

// All post routes require authentication
router.use(protect);

// Posts CRUD
router.post("/", createPost);
router.get("/", getPosts);
router.get("/:id", getPostById);
router.put("/:id", updatePost);
router.delete("/:id", deletePost);

// Like toggle
router.post("/:id/like", toggleLike);

// Comments
router.get("/:id/comments", getComments);
router.post("/:id/comments", addComment);
router.delete("/:id/comments/:commentId", deleteComment);

module.exports = router;
