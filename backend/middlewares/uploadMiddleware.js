const multer = require("multer");

// Use memory storage — file goes straight to Cloudinary, nothing written to disk
const storage = multer.memoryStorage();

const IMAGE_TYPES = ["image/jpeg", "image/jpg", "image/png", "image/gif", "image/webp"];
const VIDEO_TYPES = ["video/mp4", "video/quicktime", "video/x-msvideo", "video/x-matroska", "video/webm"];

const imageFilter = (_req, file, cb) => {
  if (IMAGE_TYPES.includes(file.mimetype)) {
    cb(null, true);
  } else {
    cb(new Error("Chỉ chấp nhận file ảnh (jpg, png, gif, webp)"), false);
  }
};

const videoFilter = (_req, file, cb) => {
  if (VIDEO_TYPES.includes(file.mimetype)) {
    cb(null, true);
  } else {
    cb(new Error("Chỉ chấp nhận file video (mp4, mov, avi, mkv, webm)"), false);
  }
};

const uploadImage = multer({
  storage,
  fileFilter: imageFilter,
  limits: { fileSize: 10 * 1024 * 1024 }, // 10 MB
}).single("file");

const uploadVideo = multer({
  storage,
  fileFilter: videoFilter,
  limits: { fileSize: 100 * 1024 * 1024 }, // 100 MB
}).single("file");

module.exports = { uploadImage, uploadVideo };
