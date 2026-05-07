const jwt = require("jsonwebtoken");
const User = require("../models/User");
const sendResponse = require("../utils/apiResponse");

const protect = async (req, res, next) => {
  try {
    const authHeader = req.headers.authorization || "";

    if (!authHeader.startsWith("Bearer ")) {
      return sendResponse(res, 401, false, "Unauthorized: token missing", {});
    }

    const token = authHeader.split(" ")[1];
    const decoded = jwt.verify(token, process.env.JWT_SECRET);

    const user = await User.findById(decoded.id).select("-password");
    if (!user) {
      return sendResponse(res, 401, false, "Unauthorized: invalid token user", {});
    }

    req.user = user;
    return next();
  } catch (error) {
    return sendResponse(res, 401, false, "Unauthorized: invalid token", {});
  }
};

module.exports = protect;
