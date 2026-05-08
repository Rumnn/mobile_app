const mongoose = require("mongoose");
const dotenv = require("dotenv");
const User = require("./models/User");
const connectDB = require("./config/db");

dotenv.config();

const seedAdmin = async () => {
  try {
    await connectDB();

    const adminExists = await User.findOne({ email: "admin@admin.com" });

    if (adminExists) {
      console.log("Admin account already exists: admin@admin.com");
      process.exit(0);
    }

    const adminUser = await User.create({
      username: "Super Admin",
      email: "admin@admin.com",
      password: "admin123", // Will be hashed automatically by pre-save hook
      role: "admin",
      level: 99,
      winRate: 100,
      totalGames: 999,
    });

    console.log("✅ Admin account created successfully!");
    console.log("Email: admin@admin.com");
    console.log("Password: admin123");

    process.exit(0);
  } catch (error) {
    console.error("Error seeding admin:", error);
    process.exit(1);
  }
};

seedAdmin();
