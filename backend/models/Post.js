const mongoose = require("mongoose");

const postSchema = new mongoose.Schema(
  {
    author: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "User",
      required: true,
    },
    content: {
      type: String,
      required: true,
      maxlength: 2000,
      trim: true,
    },
    imageURL: {
      type: String,
      default: "",
    },
    videoURL: {
      type: String,
      default: "",
    },
    likesCount: {
      type: Number,
      default: 0,
      min: 0,
    },
    commentsCount: {
      type: Number,
      default: 0,
      min: 0,
    },
  },
  { timestamps: true }
);

postSchema.index({ createdAt: -1 });
postSchema.index({ author: 1, createdAt: -1 });

module.exports = mongoose.model("Post", postSchema);
