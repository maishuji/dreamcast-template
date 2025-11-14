// Copyright 2025 Quentin Cartier

#include <gtest/gtest.h>
#include "my_module/game_utils.h"

// Test suite for game utility functions
class GameUtilsTest : public ::testing::Test {
protected:
    void SetUp() override {
        // Setup code if needed
    }

    void TearDown() override {
        // Cleanup code if needed
    }
};

// Test rotation angle normalization
TEST_F(GameUtilsTest, NormalizeAngle) {
    // Test normal case
    EXPECT_FLOAT_EQ(GameUtils::normalizeAngle(180.0f), 180.0f);
    
    // Test wrap around at 360
    EXPECT_FLOAT_EQ(GameUtils::normalizeAngle(365.0f), 5.0f);
    EXPECT_FLOAT_EQ(GameUtils::normalizeAngle(720.0f), 0.0f);
    
    // Test negative angles
    EXPECT_FLOAT_EQ(GameUtils::normalizeAngle(-10.0f), 350.0f);
    EXPECT_FLOAT_EQ(GameUtils::normalizeAngle(-360.0f), 0.0f);
    
    // Test boundary conditions
    EXPECT_FLOAT_EQ(GameUtils::normalizeAngle(0.0f), 0.0f);
    EXPECT_FLOAT_EQ(GameUtils::normalizeAngle(359.9f), 359.9f);
}

// Test rotation angle increment
TEST_F(GameUtilsTest, IncrementAngle) {
    // Test normal increment
    EXPECT_FLOAT_EQ(GameUtils::incrementAngle(45.0f, 15.0f), 60.0f);
    
    // Test wrap around
    EXPECT_FLOAT_EQ(GameUtils::incrementAngle(350.0f, 15.0f), 5.0f);
    
    // Test negative increment
    EXPECT_FLOAT_EQ(GameUtils::incrementAngle(10.0f, -15.0f), 355.0f);
}

// Test string formatting
TEST_F(GameUtilsTest, FormatFloatWithPrecision) {
    EXPECT_EQ(GameUtils::formatFloatWithPrecision(123.456f, 3), "123.456");
    EXPECT_EQ(GameUtils::formatFloatWithPrecision(123.456f, 1), "123.5");
    EXPECT_EQ(GameUtils::formatFloatWithPrecision(123.0f, 2), "123.00");
}

// Test rotation display text
TEST_F(GameUtilsTest, CreateRotationDisplayText) {
    std::string result = GameUtils::createRotationDisplayText(45.678f);
    EXPECT_EQ(result, "Rotation angle: 45.678");
}

// Test frame time calculation
TEST_F(GameUtilsTest, CalculateFrameTime) {
    EXPECT_NEAR(GameUtils::calculateFrameTime(60), 0.01667f, 0.0001f);
    EXPECT_NEAR(GameUtils::calculateFrameTime(30), 0.03333f, 0.0001f);
    EXPECT_FLOAT_EQ(GameUtils::calculateFrameTime(0), 0.0f);
    EXPECT_FLOAT_EQ(GameUtils::calculateFrameTime(-10), 0.0f);
}

// Test frame rate validation
TEST_F(GameUtilsTest, IsValidFrameRate) {
    EXPECT_TRUE(GameUtils::isValidFrameRate(60));
    EXPECT_TRUE(GameUtils::isValidFrameRate(30));
    EXPECT_TRUE(GameUtils::isValidFrameRate(120));
    EXPECT_TRUE(GameUtils::isValidFrameRate(1));
    
    EXPECT_FALSE(GameUtils::isValidFrameRate(0));
    EXPECT_FALSE(GameUtils::isValidFrameRate(-10));
    EXPECT_FALSE(GameUtils::isValidFrameRate(1001));
}

// Test camera configuration
TEST_F(GameUtilsTest, CreateDefaultCamera) {
    auto camera = GameUtils::createDefaultCamera();
    
    EXPECT_FLOAT_EQ(camera.posX, 4.0f);
    EXPECT_FLOAT_EQ(camera.posY, 4.0f);
    EXPECT_FLOAT_EQ(camera.posZ, 4.0f);
    EXPECT_FLOAT_EQ(camera.targetX, 0.0f);
    EXPECT_FLOAT_EQ(camera.targetY, 0.0f);
    EXPECT_FLOAT_EQ(camera.targetZ, 0.0f);
    EXPECT_FLOAT_EQ(camera.upX, 0.0f);
    EXPECT_FLOAT_EQ(camera.upY, 1.0f);
    EXPECT_FLOAT_EQ(camera.upZ, 0.0f);
    EXPECT_FLOAT_EQ(camera.fovy, 45.0f);
}

// Test camera configuration validation
TEST_F(GameUtilsTest, IsValidCameraConfig) {
    auto validCamera = GameUtils::createDefaultCamera();
    EXPECT_TRUE(GameUtils::isValidCameraConfig(validCamera));
    
    // Test invalid FOV
    auto invalidFOV = validCamera;
    invalidFOV.fovy = 0.0f;
    EXPECT_FALSE(GameUtils::isValidCameraConfig(invalidFOV));
    
    invalidFOV.fovy = 180.0f;
    EXPECT_FALSE(GameUtils::isValidCameraConfig(invalidFOV));
    
    // Test zero up vector
    auto zeroUp = validCamera;
    zeroUp.upX = 0.0f;
    zeroUp.upY = 0.0f;
    zeroUp.upZ = 0.0f;
    EXPECT_FALSE(GameUtils::isValidCameraConfig(zeroUp));
}
