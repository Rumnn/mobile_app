const mongoose = require("mongoose");
const Follow = require("../models/Follow");
const User = require("../models/User");
const sendResponse = require("../utils/apiResponse");

const follow = async (req, res, next) => {
  try {
    const { id } = req.params;
    if (!mongoose.Types.ObjectId.isValid(id)) {
      return sendResponse(res, 400, false, "Invalid user id", {});
    }

    if (id === req.user._id.toString()) {
      return sendResponse(res, 400, false, "Cannot follow yourself", {});
    }

    const targetUser = await User.findById(id);
    if (!targetUser) {
      return sendResponse(res, 404, false, "User not found", {});
    }

    const existing = await Follow.findOne({
      follower: req.user._id,
      following: id,
    });

    if (existing) {
      return sendResponse(res, 400, false, "Already following this user", {});
    }

    await Follow.create({ follower: req.user._id, following: id });

    const followersCount = await Follow.countDocuments({ following: id });

    return sendResponse(res, 201, true, "Followed successfully", {
      isFollowing: true,
      followersCount,
    });
  } catch (error) {
    return next(error);
  }
};

const unfollow = async (req, res, next) => {
  try {
    const { id } = req.params;
    if (!mongoose.Types.ObjectId.isValid(id)) {
      return sendResponse(res, 400, false, "Invalid user id", {});
    }

    const deleted = await Follow.findOneAndDelete({
      follower: req.user._id,
      following: id,
    });

    if (!deleted) {
      return sendResponse(res, 400, false, "Not following this user", {});
    }

    const followersCount = await Follow.countDocuments({ following: id });

    return sendResponse(res, 200, true, "Unfollowed successfully", {
      isFollowing: false,
      followersCount,
    });
  } catch (error) {
    return next(error);
  }
};

const getFollowers = async (req, res, next) => {
  try {
    const { id } = req.params;
    if (!mongoose.Types.ObjectId.isValid(id)) {
      return sendResponse(res, 400, false, "Invalid user id", {});
    }

    const followers = await Follow.find({ following: id })
      .populate("follower", "username avatarURL level")
      .lean();

    return sendResponse(res, 200, true, "Followers fetched", {
      followers: followers.map((f) => f.follower),
      count: followers.length,
    });
  } catch (error) {
    return next(error);
  }
};

const getFollowing = async (req, res, next) => {
  try {
    const { id } = req.params;
    if (!mongoose.Types.ObjectId.isValid(id)) {
      return sendResponse(res, 400, false, "Invalid user id", {});
    }

    const following = await Follow.find({ follower: id })
      .populate("following", "username avatarURL level")
      .lean();

    return sendResponse(res, 200, true, "Following list fetched", {
      following: following.map((f) => f.following),
      count: following.length,
    });
  } catch (error) {
    return next(error);
  }
};

const checkFollowing = async (req, res, next) => {
  try {
    const { id } = req.params;
    if (!mongoose.Types.ObjectId.isValid(id)) {
      return sendResponse(res, 400, false, "Invalid user id", {});
    }

    const existing = await Follow.findOne({
      follower: req.user._id,
      following: id,
    });

    return sendResponse(res, 200, true, "Follow status checked", {
      isFollowing: !!existing,
    });
  } catch (error) {
    return next(error);
  }
};

const getFriends = async (req, res, next) => {
  try {
    const currentUserId = req.user._id;

    // Find all users followed by current user
    const followingList = await Follow.find({ follower: currentUserId }).select("following");
    const followingIds = followingList.map((f) => f.following.toString());

    // Find all users who follow current user
    const followersList = await Follow.find({ following: currentUserId }).select("follower");
    const followerIds = followersList.map((f) => f.follower.toString());

    // Find the intersection (mutual followers)
    const friendIds = followingIds.filter((id) => followerIds.includes(id));

    // Fetch details of mutual friends
    const friends = await User.find({ _id: { $in: friendIds } }).select("username avatarURL level winRate totalGames role");

    return sendResponse(res, 200, true, "Friends list fetched successfully", { friends });
  } catch (error) {
    return next(error);
  }
};

module.exports = {
  follow,
  unfollow,
  getFollowers,
  getFollowing,
  checkFollowing,
  getFriends,
};

