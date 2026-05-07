const sendResponse = require("../utils/apiResponse");

const notFoundHandler = (req, res) => {
  return sendResponse(res, 404, false, "Route not found", {});
};

const errorHandler = (err, req, res, next) => {
  const isDev = process.env.NODE_ENV !== "production";

  // eslint-disable-next-line no-console
  console.error(err?.stack || err);

  // Default
  let statusCode = 500;
  let message = "Internal server error";

  // Mongoose validation
  if (err?.name === "ValidationError") {
    statusCode = 400;
    message = Object.values(err.errors || {})
      .map((e) => e.message)
      .filter(Boolean)
      .join(", ") || "Validation error";
  }

  // Duplicate key
  if (err?.code === 11000) {
    statusCode = 400;
    const fields = Object.keys(err.keyValue || {}).join(", ");
    message = fields ? `${fields} already exists` : "Duplicate key error";
  }

  // JWT
  if (err?.name === "JsonWebTokenError" || err?.name === "TokenExpiredError") {
    statusCode = 401;
    message = "Unauthorized: invalid token";
  }

  // Surface message in dev for faster debugging
  if (isDev && err?.message && message === "Internal server error") {
    message = err.message;
  }

  return sendResponse(res, statusCode, false, message, {});
};

module.exports = {
  notFoundHandler,
  errorHandler,
};
