const express = require("express");
const { createUser, getUsers, getUserById, updateUser, deleteUser } = require("../controllers/userController");
const { follow, unfollow, getFollowers, getFollowing, checkFollowing } = require("../controllers/followController");
const protect = require("../middlewares/authMiddleware");
const authorizeRoles = require("../middlewares/roleMiddleware");

const router = express.Router();

router.get("/", protect, getUsers);
router.get("/:id", protect, getUserById);
router.post("/", protect, authorizeRoles("admin"), createUser);
router.put("/:id", protect, updateUser);
router.delete("/:id", protect, authorizeRoles("admin"), deleteUser);

// Follow system
router.post("/:id/follow", protect, follow);
router.delete("/:id/follow", protect, unfollow);
router.get("/:id/follow/check", protect, checkFollowing);
router.get("/:id/followers", protect, getFollowers);
router.get("/:id/following", protect, getFollowing);

module.exports = router;
