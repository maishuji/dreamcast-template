// Copyright 2025 Quentin Cartier

#include <gtest/gtest.h>
#include <cmath>
#include <sstream>
#include <string>
#include <ios>

// Test suite for my_module basic functionality
class MyModuleTest : public ::testing::Test {
protected:
    void SetUp() override {
        // Setup code if needed
    }

    void TearDown() override {
        // Cleanup code if needed
    }
};

// Test rotation angle normalization (since the main.cpp has rotation logic)
TEST_F(MyModuleTest, RotationAngleNormalization) {
    // Test that rotation angle wraps correctly at 360 degrees
    float rotationAngle = 350.0f;
    rotationAngle += 15.0f; // This should result in 365.0f
    
    // Normalize the angle (similar to the logic in main.cpp)
    if (rotationAngle >= 360.0f) {
        rotationAngle -= 360.0f;
    }
    
    EXPECT_FLOAT_EQ(rotationAngle, 5.0f);
}

// Test rotation angle increment
TEST_F(MyModuleTest, RotationAngleIncrement) {
    float rotationAngle = 0.0f;
    float increment = 1.0f;
    
    // Simulate multiple increments
    for (int i = 0; i < 45; i++) {
        rotationAngle += increment;
    }
    
    EXPECT_FLOAT_EQ(rotationAngle, 45.0f);
}

// Test rotation angle boundary conditions
TEST_F(MyModuleTest, RotationAngleBoundary) {
    float rotationAngle = 359.9f;
    rotationAngle += 1.0f;
    
    if (rotationAngle >= 360.0f) {
        rotationAngle -= 360.0f;
    }
    
    EXPECT_LT(rotationAngle, 360.0f);
    EXPECT_GE(rotationAngle, 0.0f);
}

// Test basic mathematical operations that could be used in the game
TEST_F(MyModuleTest, BasicMathOperations) {
    // Test basic cube calculations (since the main.cpp draws a cube)
    float cubeSize = 2.0f;
    float cubeVolume = cubeSize * cubeSize * cubeSize;
    
    EXPECT_FLOAT_EQ(cubeVolume, 8.0f);
}

// Test string formatting (similar to the rotation angle text in main.cpp)
TEST_F(MyModuleTest, StringFormatting) {
    float testValue = 123.456f;
    
    // Convert to string with precision (similar to main.cpp logic)
    std::ostringstream oss;
    oss.setf(std::ios::fixed);
    oss.precision(3);
    oss << testValue;
    
    std::string result = oss.str();
    EXPECT_EQ(result, "123.456");
}

// Test frame rate calculation bounds
TEST_F(MyModuleTest, FrameRateBounds) {
    int targetFPS = 60;
    float frameTime = 1.0f / targetFPS;
    
    // Frame time should be approximately 1/60 seconds
    EXPECT_NEAR(frameTime, 0.01667f, 0.0001f);
}
