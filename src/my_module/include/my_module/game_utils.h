// Copyright 2025 Quentin Cartier

#pragma once

#include <string>

namespace GameUtils {
// Rotation angle utilities
float normalizeAngle(float angle);
float incrementAngle(float currentAngle, float increment);

// String formatting utilities
std::string formatFloatWithPrecision(float value, int precision);
std::string createRotationDisplayText(float angle);

// Frame rate utilities
float calculateFrameTime(int targetFPS);
bool isValidFrameRate(int fps);

// Camera utilities
struct CameraConfig {
    float posX, posY, posZ;
    float targetX, targetY, targetZ;
    float upX, upY, upZ;
    float fovy;
};

CameraConfig createDefaultCamera();
bool isValidCameraConfig(const CameraConfig& config);
}  // namespace GameUtils
