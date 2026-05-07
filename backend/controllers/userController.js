const mongoose = require("mongoose");
const User = require("../models/User");
const sendResponse = require("../utils/apiResponse");
const sanitizeUser = require("../utils/sanitizeUser");

const filterPublicFields = (user) => ({
  _id: user._id,
  username: user.username,
  avatarURL: user.avatarURL,
  level: user.level,
  winRate: user.winRate,
  totalGames: user.totalGames,
  role: user.role,
});

const getUsers = async (req, res, next) => {
  try {
    const users = await User.find().select("-password");

    const data =
      req.user.role === "admin" ? users.map(sanitizeUser) : users.map((user) => filterPublicFields(user));

    return sendResponse(res, 200, true, "Users fetched successfully", { users: data });
  } catch (error) {
    return next(error);
  }
};

const createUser = async (req, res, next) => {
  try {
    if (req.user.role !== "admin") {
      return sendResponse(res, 403, false, "Forbidden: insufficient permissions", {});
    }

    const { username, email, password, avatarURL, level, winRate, totalGames, role } = req.body;
    if (!username || !email || !password) {
      return sendResponse(res, 400, false, "username, email, and password are required", {});
    }

    const exists = await User.findOne({ email });
    if (exists) {
      return sendResponse(res, 400, false, "Email already registered", {});
    }

    const user = await User.create({
      username,
      email,
      password,
      avatarURL,
      level,
      winRate,
      totalGames,
      role: role || "user",
    });

    return sendResponse(res, 201, true, "User created successfully", { user: sanitizeUser(user) });
  } catch (error) {
    return next(error);
  }
};

const updateUser = async (req, res, next) => {
  try {
    const { id } = req.params;
    if (!mongoose.Types.ObjectId.isValid(id)) {
      return sendResponse(res, 400, false, "Invalid user id", {});
    }

    const isAdmin = req.user.role === "admin";
    const isSelf = req.user._id.toString() === id;

    if (!isAdmin && !isSelf) {
      return sendResponse(res, 403, false, "Forbidden: cannot update another user", {});
    }

    const allowedFields = ["username", "avatarURL", "level", "winRate", "totalGames", "email"];
    if (isAdmin) {
      allowedFields.push("role");
    }

    const updatePayload = {};
    allowedFields.forEach((field) => {
      if (req.body[field] !== undefined) {
        updatePayload[field] = req.body[field];
      }
    });

    if (Object.keys(updatePayload).length === 0) {
      return sendResponse(res, 400, false, "No valid fields provided to update", {});
    }

    const updatedUser = await User.findByIdAndUpdate(id, updatePayload, {
      new: true,
      runValidators: true,
      context: "query",
    }).select("-password");

    if (!updatedUser) {
      return sendResponse(res, 404, false, "User not found", {});
    }

    return sendResponse(res, 200, true, "User updated successfully", {
      user: sanitizeUser(updatedUser),
    });
  } catch (error) {
    return next(error);
  }
};

const deleteUser = async (req, res, next) => {
  try {
    const { id } = req.params;
    if (!mongoose.Types.ObjectId.isValid(id)) {
      return sendResponse(res, 400, false, "Invalid user id", {});
    }

    const deletedUser = await User.findByIdAndDelete(id);

    if (!deletedUser) {
      return sendResponse(res, 404, false, "User not found", {});
    }

    return sendResponse(res, 200, true, "User deleted successfully", {
      user: sanitizeUser(deletedUser),
    });
  } catch (error) {
    return next(error);
  }
};

module.exports = {
  createUser,
  getUsers,
  updateUser,
  deleteUser,
};
