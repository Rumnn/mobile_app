const express = require("express");
const { createUser, getUsers, getUserById, updateUser, deleteUser } = require("../controllers/userController");
const protect = require("../middlewares/authMiddleware");
const authorizeRoles = require("../middlewares/roleMiddleware");

const router = express.Router();

router.get("/", protect, getUsers);
router.get("/:id", protect, getUserById);
router.post("/", protect, authorizeRoles("admin"), createUser);
router.put("/:id", protect, updateUser);
router.delete("/:id", protect, authorizeRoles("admin"), deleteUser);

module.exports = router;
