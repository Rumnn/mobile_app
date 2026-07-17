const { v2: cloudinary } = require("cloudinary");

/**
 * Returns a configured Cloudinary instance.
 * Called lazily at request time so env vars are guaranteed to be loaded.
 */
const getCloudinary = () => {
  cloudinary.config({
    cloud_name: process.env.CLOUDINARY_CLOUD_NAME,
    api_key:    process.env.CLOUDINARY_API_KEY,
    api_secret: process.env.CLOUDINARY_API_SECRET,
  });
  return cloudinary;
};

module.exports = getCloudinary;
