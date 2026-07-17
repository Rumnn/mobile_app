const express = require("express");
const router = express.Router();

const { uploadImage, uploadVideo } = require("../middlewares/uploadMiddleware");
const { uploadImageHandler, uploadVideoHandler } = require("../controllers/uploadController");
const protect = require("../middlewares/authMiddleware");

// All upload endpoints require authentication
router.post("/image", protect, (req, res, next) => {
  uploadImage(req, res, (err) => {
    if (err) {
      return res.status(400).json({ success: false, message: err.message, data: {} });
    }
    uploadImageHandler(req, res);
  });
});

router.post("/video", protect, (req, res, next) => {
  uploadVideo(req, res, (err) => {
    if (err) {
      return res.status(400).json({ success: false, message: err.message, data: {} });
    }
    uploadVideoHandler(req, res);
  });
});

module.exports = router;
