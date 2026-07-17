const mongoose = require("mongoose");

const communityMessageSchema = new mongoose.Schema(
  {
    sender: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "User",
      required: true,
    },
    content: {
      type: String,
      required: true,
      trim: true,
      maxlength: 1000,
    },
  },
  { timestamps: true }
);

communityMessageSchema.index({ createdAt: 1 });

module.exports = mongoose.model("CommunityMessage", communityMessageSchema);
