const getCloudinary = require("../config/cloudinary");
const sendResponse = require("../utils/apiResponse");
const { Readable } = require("stream");

// Helper: upload a buffer to Cloudinary via a stream
const uploadToCloudinary = (buffer, options) =>
  new Promise((resolve, reject) => {
    const cloudinary = getCloudinary();
    const stream = cloudinary.uploader.upload_stream(options, (error, result) => {
      if (error) return reject(error);
      resolve(result);
    });
    Readable.from(buffer).pipe(stream);
  });

// POST /upload/image
const uploadImageHandler = async (req, res) => {
  if (!req.file) {
    return sendResponse(res, 400, false, "Không có file nào được gửi lên", {});
  }
  try {
    const result = await uploadToCloudinary(req.file.buffer, {
      folder: "playsphere/images",
      resource_type: "image",
      // Auto quality + format for web delivery
      transformation: [{ quality: "auto", fetch_format: "auto" }],
    });
    return sendResponse(res, 200, true, "Upload ảnh thành công", {
      url: result.secure_url,
      publicId: result.public_id,
    });
  } catch (err) {
    return sendResponse(res, 500, false, `Cloudinary error: ${err.message}`, {});
  }
};

// POST /upload/video
const uploadVideoHandler = async (req, res) => {
  if (!req.file) {
    return sendResponse(res, 400, false, "Không có file nào được gửi lên", {});
  }
  try {
    const result = await uploadToCloudinary(req.file.buffer, {
      folder: "playsphere/videos",
      resource_type: "video",
    });
    return sendResponse(res, 200, true, "Upload video thành công", {
      url: result.secure_url,
      publicId: result.public_id,
    });
  } catch (err) {
    return sendResponse(res, 500, false, `Cloudinary error: ${err.message}`, {});
  }
};

module.exports = { uploadImageHandler, uploadVideoHandler };
