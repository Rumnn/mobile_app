const jwt = require("jsonwebtoken");
const User = require("../models/User");
const sendResponse = require("../utils/apiResponse");
const sanitizeUser = require("../utils/sanitizeUser");

const signToken = (id, role) => {
  return jwt.sign({ id, role }, process.env.JWT_SECRET, {
    expiresIn: process.env.JWT_EXPIRES_IN || "7d",
  });
};

const register = async (req, res, next) => {
  try {
    const { username, email, password, avatarURL, level, winRate, totalGames, role } = req.body;
    if (!username || !email || !password) {
      return sendResponse(res, 400, false, "username, email, and password are required", {});
    }

    const existingUser = await User.findOne({ email });
    if (existingUser) {
      return sendResponse(res, 400, false, "Email already registered", {});
    }

    const newUser = await User.create({
      username,
      email,
      password,
      avatarURL,
      level,
      winRate,
      totalGames,
      role: role || "user",
    });

    const token = signToken(newUser._id, newUser.role);
    return sendResponse(res, 201, true, "Register successful", {
      token,
      user: sanitizeUser(newUser),
    });
  } catch (error) {
    return next(error);
  }
};

const login = async (req, res, next) => {
  try {
    const { email, password } = req.body;
    if (!email || !password) {
      return sendResponse(res, 400, false, "email and password are required", {});
    }

    const user = await User.findOne({ email });
    if (!user) {
      return sendResponse(res, 401, false, "Invalid email or password", {});
    }

    const isMatched = await user.comparePassword(password);
    if (!isMatched) {
      return sendResponse(res, 401, false, "Invalid email or password", {});
    }

    const token = signToken(user._id, user.role);
    return sendResponse(res, 200, true, "Login successful", {
      token,
      user: sanitizeUser(user),
    });
  } catch (error) {
    return next(error);
  }
};

module.exports = {
  register,
  login,
};
