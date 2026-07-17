const mongoose = require("mongoose");
const Post = require("../models/Post");
const Comment = require("../models/Comment");
const Like = require("../models/Like");
const sendResponse = require("../utils/apiResponse");

const POSTS_PER_PAGE = 20;
const COMMENTS_PER_PAGE = 20;

// ─── Posts CRUD ──────────────────────────────────────────────

const createPost = async (req, res, next) => {
  try {
    const { content, imageURL, videoURL } = req.body;
    if (!content || !content.trim()) {
      return sendResponse(res, 400, false, "Post content is required", {});
    }

    const post = await Post.create({
      author: req.user._id,
      content: content.trim(),
      imageURL: imageURL || "",
      videoURL: videoURL || "",
    });

    const populated = await post.populate("author", "username avatarURL");

    const createdPost = {
      ...populated.toObject(),
      isLiked: false,
    };

    const io = req.app.get("io");
    if (io) {
      io.emit("post_created", { post: createdPost });
    }

    return sendResponse(res, 201, true, "Post created successfully", {
      post: createdPost,
    });
  } catch (error) {
    return next(error);
  }
};

const getPosts = async (req, res, next) => {
  try {
    const page = Math.max(parseInt(req.query.page, 10) || 1, 1);
    const limit = Math.min(parseInt(req.query.limit, 10) || POSTS_PER_PAGE, 50);
    const skip = (page - 1) * limit;

    const [posts, total] = await Promise.all([
      Post.find()
        .sort({ createdAt: -1 })
        .skip(skip)
        .limit(limit)
        .populate("author", "username avatarURL")
        .lean(),
      Post.countDocuments(),
    ]);

    // Determine which posts the current user has liked
    const postIds = posts.map((p) => p._id);
    const userLikes = await Like.find({
      post: { $in: postIds },
      user: req.user._id,
    }).lean();
    const likedSet = new Set(userLikes.map((l) => l.post.toString()));

    const enriched = posts.map((p) => ({
      ...p,
      isLiked: likedSet.has(p._id.toString()),
    }));

    return sendResponse(res, 200, true, "Posts fetched successfully", {
      posts: enriched,
      pagination: {
        page,
        limit,
        total,
        totalPages: Math.ceil(total / limit),
      },
    });
  } catch (error) {
    return next(error);
  }
};

const getPostById = async (req, res, next) => {
  try {
    const { id } = req.params;
    if (!mongoose.Types.ObjectId.isValid(id)) {
      return sendResponse(res, 400, false, "Invalid post id", {});
    }

    const post = await Post.findById(id)
      .populate("author", "username avatarURL")
      .lean();

    if (!post) {
      return sendResponse(res, 404, false, "Post not found", {});
    }

    const liked = await Like.exists({ post: id, user: req.user._id });

    return sendResponse(res, 200, true, "Post fetched successfully", {
      post: { ...post, isLiked: !!liked },
    });
  } catch (error) {
    return next(error);
  }
};

const updatePost = async (req, res, next) => {
  try {
    const { id } = req.params;
    if (!mongoose.Types.ObjectId.isValid(id)) {
      return sendResponse(res, 400, false, "Invalid post id", {});
    }

    const post = await Post.findById(id);
    if (!post) {
      return sendResponse(res, 404, false, "Post not found", {});
    }

    const isOwner = post.author.toString() === req.user._id.toString();
    const isAdmin = req.user.role === "admin";
    if (!isOwner && !isAdmin) {
      return sendResponse(res, 403, false, "Forbidden: cannot edit this post", {});
    }

    const { content, imageURL, videoURL } = req.body;
    if (content !== undefined) post.content = content.trim();
    if (imageURL !== undefined) post.imageURL = imageURL;
    if (videoURL !== undefined) post.videoURL = videoURL;

    await post.save();
    await post.populate("author", "username avatarURL");

    const liked = await Like.exists({ post: id, user: req.user._id });

    const updatedPost = { ...post.toObject(), isLiked: !!liked };

    const io = req.app.get("io");
    if (io) {
      io.emit("post_updated", { post: updatedPost });
    }

    return sendResponse(res, 200, true, "Post updated successfully", {
      post: updatedPost,
    });
  } catch (error) {
    return next(error);
  }
};

const deletePost = async (req, res, next) => {
  try {
    const { id } = req.params;
    if (!mongoose.Types.ObjectId.isValid(id)) {
      return sendResponse(res, 400, false, "Invalid post id", {});
    }

    const post = await Post.findById(id);
    if (!post) {
      return sendResponse(res, 404, false, "Post not found", {});
    }

    const isOwner = post.author.toString() === req.user._id.toString();
    const isAdmin = req.user.role === "admin";
    if (!isOwner && !isAdmin) {
      return sendResponse(res, 403, false, "Forbidden: cannot delete this post", {});
    }

    // Cascade delete comments and likes
    await Promise.all([
      Comment.deleteMany({ post: id }),
      Like.deleteMany({ post: id }),
      post.deleteOne(),
    ]);

    const io = req.app.get("io");
    if (io) {
      io.emit("post_deleted", { postId: id });
    }

    return sendResponse(res, 200, true, "Post deleted successfully", {});
  } catch (error) {
    return next(error);
  }
};

// ─── Like / Unlike (toggle) ─────────────────────────────────

const toggleLike = async (req, res, next) => {
  try {
    const { id } = req.params;
    if (!mongoose.Types.ObjectId.isValid(id)) {
      return sendResponse(res, 400, false, "Invalid post id", {});
    }

    const post = await Post.findById(id);
    if (!post) {
      return sendResponse(res, 404, false, "Post not found", {});
    }

    const existing = await Like.findOne({ post: id, user: req.user._id });

    if (existing) {
      await existing.deleteOne();
      post.likesCount = Math.max(post.likesCount - 1, 0);
      await post.save();

      const io = req.app.get("io");
      if (io) {
        io.emit("post_likes_updated", { postId: id, likesCount: post.likesCount });
      }

      return sendResponse(res, 200, true, "Post unliked", {
        isLiked: false,
        likesCount: post.likesCount,
      });
    }

    await Like.create({ post: id, user: req.user._id });
    post.likesCount += 1;
    await post.save();

    const io = req.app.get("io");
    if (io) {
      io.emit("post_likes_updated", { postId: id, likesCount: post.likesCount });
    }

    return sendResponse(res, 200, true, "Post liked", {
      isLiked: true,
      likesCount: post.likesCount,
    });
  } catch (error) {
    return next(error);
  }
};

// ─── Comments ────────────────────────────────────────────────

const getComments = async (req, res, next) => {
  try {
    const { id } = req.params;
    if (!mongoose.Types.ObjectId.isValid(id)) {
      return sendResponse(res, 400, false, "Invalid post id", {});
    }

    const page = Math.max(parseInt(req.query.page, 10) || 1, 1);
    const limit = Math.min(parseInt(req.query.limit, 10) || COMMENTS_PER_PAGE, 50);
    const skip = (page - 1) * limit;

    const [comments, total] = await Promise.all([
      Comment.find({ post: id })
        .sort({ createdAt: -1 })
        .skip(skip)
        .limit(limit)
        .populate("author", "username avatarURL")
        .lean(),
      Comment.countDocuments({ post: id }),
    ]);

    return sendResponse(res, 200, true, "Comments fetched successfully", {
      comments,
      pagination: { page, limit, total, totalPages: Math.ceil(total / limit) },
    });
  } catch (error) {
    return next(error);
  }
};

const addComment = async (req, res, next) => {
  try {
    const { id } = req.params;
    if (!mongoose.Types.ObjectId.isValid(id)) {
      return sendResponse(res, 400, false, "Invalid post id", {});
    }

    const post = await Post.findById(id);
    if (!post) {
      return sendResponse(res, 404, false, "Post not found", {});
    }

    const { content } = req.body;
    if (!content || !content.trim()) {
      return sendResponse(res, 400, false, "Comment content is required", {});
    }

    const comment = await Comment.create({
      post: id,
      author: req.user._id,
      content: content.trim(),
    });

    post.commentsCount += 1;
    await post.save();

    const populated = await comment.populate("author", "username avatarURL");

    const io = req.app.get("io");
    if (io) {
      io.emit("comment_added", {
        postId: id,
        comment: populated.toObject(),
        commentsCount: post.commentsCount,
      });
    }

    return sendResponse(res, 201, true, "Comment added successfully", {
      comment: populated.toObject(),
      commentsCount: post.commentsCount,
    });
  } catch (error) {
    return next(error);
  }
};

const deleteComment = async (req, res, next) => {
  try {
    const { id, commentId } = req.params;
    if (!mongoose.Types.ObjectId.isValid(id) || !mongoose.Types.ObjectId.isValid(commentId)) {
      return sendResponse(res, 400, false, "Invalid id", {});
    }

    const comment = await Comment.findById(commentId);
    if (!comment || comment.post.toString() !== id) {
      return sendResponse(res, 404, false, "Comment not found", {});
    }

    const isOwner = comment.author.toString() === req.user._id.toString();
    const isAdmin = req.user.role === "admin";
    if (!isOwner && !isAdmin) {
      return sendResponse(res, 403, false, "Forbidden: cannot delete this comment", {});
    }

    await comment.deleteOne();

    const post = await Post.findById(id);
    if (post) {
      post.commentsCount = Math.max(post.commentsCount - 1, 0);
      await post.save();
    }

    const io = req.app.get("io");
    if (io) {
      io.emit("comment_deleted", {
        postId: id,
        commentId,
        commentsCount: post ? post.commentsCount : 0,
      });
    }

    return sendResponse(res, 200, true, "Comment deleted successfully", {
      commentsCount: post ? post.commentsCount : 0,
    });
  } catch (error) {
    return next(error);
  }
};

module.exports = {
  createPost,
  getPosts,
  getPostById,
  updatePost,
  deletePost,
  toggleLike,
  getComments,
  addComment,
  deleteComment,
};
