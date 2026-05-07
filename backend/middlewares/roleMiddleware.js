const sendResponse = require("../utils/apiResponse");

const authorizeRoles = (...roles) => {
  return (req, res, next) => {
    if (!req.user || !roles.includes(req.user.role)) {
      return sendResponse(res, 403, false, "Forbidden: insufficient permissions", {});
    }

    return next();
  };
};

module.exports = authorizeRoles;
